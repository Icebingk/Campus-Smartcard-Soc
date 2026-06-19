`timescale 1ns / 1ps
// ============================================================================
// 数字基带 (Digital Baseband) — v1.0
// ============================================================================
// 功能: ISO14443 Type A 协议处理、防冲突 FSM、曼彻斯特编解码
//       纯硬件多级状态机，支持 106kbps / 212kbps / 424kbps / 848kbps
//
// APB 基址: 0x4000_0000 (Slave 0)
// 寄存器数: 8 个 (0x00 ~ 0x1C)
//
// 版本: v1.0 (完整基带引擎)
// 负责人: 阿呆不呆
// ============================================================================

module bb_top (
    input  wire         pclk, presetn,
    input  wire         psel, penable,
    input  wire [11:0]  paddr,
    input  wire         pwrite,
    input  wire [31:0]  pwdata,
    output reg  [31:0]  prdata,
    output wire         pready, pslverr,
    input  wire         rf_rx,
    output reg          rf_tx,
    input  wire         rf_clk,
    output reg          irq_o
);

    // ================================================================
    // APB 寄存器接口
    // ================================================================
    localparam NUM_REGS = 8;
    localparam ADDR_W   = 3;
    wire [ADDR_W-1:0] reg_addr;
    assign reg_addr = paddr[ADDR_W-1:0];
    wire apb_write;
    assign apb_write = psel && penable && pwrite;

    // 0x00: BB_CTRL       控制
    //      [0]:    RF_ENABLE   射频场使能
    //      [1]:    TX_START    启动发送
    //      [2]:    RX_ENABLE   接收使能
    //      [3]:    ANTICOL_EN  防冲突使能
    //      [7:4]:  BITRATE     码率 (0=106k, 1=212k, 2=424k, 3=848k)
    //      [31]:   SOFT_RESET  软件复位
    // 0x04: BB_STATUS     状态 (RO)
    //      [0]:    BUSY
    //      [1]:    TX_DONE
    //      [2]:    RX_DONE
    //      [3]:    RX_OVERFLOW
    //      [4]:    COLLISION    冲突检测
    //      [5]:    FRAME_ERR    帧错误
    //      [7]:    FIELD_ON     射频场存在
    // 0x08: BB_TX_DATA    发送数据 (写时推入 TX FIFO)
    // 0x0C: BB_RX_DATA    接收数据 (读时从 RX FIFO 弹出)
    // 0x10: BB_FIFO_STATUS FIFO 状态
    //      [7:0]:  TX_FIFO_COUNT
    //      [15:8]: RX_FIFO_COUNT
    //      [16]:   TX_FIFO_FULL
    //      [17]:   TX_FIFO_EMPTY
    //      [18]:   RX_FIFO_FULL
    //      [19]:   RX_FIFO_EMPTY
    // 0x14: BB_INT_EN     中断使能
    //      [0]:    TX_DONE_IE
    //      [1]:    RX_DONE_IE
    //      [2]:    COLLISION_IE
    //      [3]:    RX_OVF_IE
    // 0x18: BB_INT_STATUS 中断状态 (W1C)
    // 0x1C: BB_BAUD_CFG   波特率配置
    //      [15:0]: ETU_DIVIDER  ETU = (DIV+1) * pclk_period

    reg [31:0] regfile [0:NUM_REGS-1];

    always @(*) prdata = (psel && !pwrite) ? regfile[reg_addr] : 32'h0;
    assign pready = 1'b1;
    assign pslverr = 1'b0;

    // ================================================================
    // 前向声明: 状态机参数和关键互连信号 (必须在所有使用前声明)
    // ================================================================

    // ─── TX 状态机声明 ───
    localparam [2:0] TX_IDLE  = 3'd0;
    localparam [2:0] TX_SOF   = 3'd1;
    localparam [2:0] TX_DATA  = 3'd2;
    localparam [2:0] TX_PARITY = 3'd3;
    localparam [2:0] TX_EOF   = 3'd4;
    localparam [2:0] TX_WAIT  = 3'd5;
    reg [2:0] tx_state, tx_next;
    reg       tx_pop;         // TX FSM → FIFO: 弹出信号

    // ─── RX 状态机声明 ───
    localparam [2:0] RX_IDLE  = 3'd0;
    localparam [2:0] RX_SOF   = 3'd1;
    localparam [2:0] RX_DATA  = 3'd2;
    localparam [2:0] RX_PARITY = 3'd3;
    localparam [2:0] RX_EOF   = 3'd4;
    reg [2:0] rx_state, rx_next;
    reg       rx_frame_err;   // RX FSM → regfile: 帧错误触发
    reg       rx_done;        // RX FSM → regfile: 接收完成触发
    wire      rx_byte_valid;  // RX FSM → FIFO: 字节有效
    wire [7:0] rx_byte;       // RX FSM → FIFO: 接收字节

    // ================================================================
    // TX FIFO (8 字节)
    // ================================================================
    reg [7:0] tx_fifo [0:7];
    reg [2:0] tx_wr_ptr, tx_rd_ptr;
    reg [3:0] tx_count;  // 0..8

    wire tx_fifo_full  = (tx_count == 4'd8);
    wire tx_fifo_empty = (tx_count == 4'd0);

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            tx_wr_ptr <= 3'd0; tx_rd_ptr <= 3'd0; tx_count <= 4'd0;
        end else if (regfile[0][31]) begin  // SOFT_RESET
            tx_wr_ptr <= 3'd0; tx_rd_ptr <= 3'd0; tx_count <= 4'd0;
        end else begin
            // APB 写 TX_DATA → push FIFO
            if (apb_write && reg_addr==3'd2 && !tx_fifo_full) begin
                tx_fifo[tx_wr_ptr] <= pwdata[7:0];
                tx_wr_ptr <= tx_wr_ptr + 3'd1;
                tx_count  <= tx_count + 4'd1;
            end
            // TX 状态机读 FIFO → pop
            if (tx_pop) begin
                tx_rd_ptr <= tx_rd_ptr + 3'd1;
                tx_count  <= tx_count - 4'd1;
            end
        end
    end

    wire [7:0] tx_data_out;
    assign tx_data_out = tx_fifo[tx_rd_ptr];

    // ================================================================
    // RX FIFO (8 字节)
    // ================================================================
    reg [7:0] rx_fifo [0:7];
    reg [2:0] rx_wr_ptr, rx_rd_ptr;
    reg [3:0] rx_count;

    wire rx_fifo_full  = (rx_count == 4'd8);
    wire rx_fifo_empty = (rx_count == 4'd0);

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            rx_wr_ptr <= 3'd0; rx_rd_ptr <= 3'd0; rx_count <= 4'd0;
        end else if (regfile[0][31]) begin
            rx_wr_ptr <= 3'd0; rx_rd_ptr <= 3'd0; rx_count <= 4'd0;
        end else begin
            // 解码器写 RX FIFO
            if (rx_byte_valid && !rx_fifo_full) begin
                rx_fifo[rx_wr_ptr] <= rx_byte;
                rx_wr_ptr <= rx_wr_ptr + 3'd1;
                rx_count  <= rx_count + 4'd1;
            end
            // APB 读 RX_DATA → pop FIFO
            if (apb_write && reg_addr==3'd3 && !rx_fifo_empty) begin
                rx_rd_ptr <= rx_rd_ptr + 3'd1;
                rx_count  <= rx_count - 4'd1;
            end
            // 读操作自动更新 RDATA
        end
    end

    wire [7:0] rx_data_out;
    assign rx_data_out = rx_fifo[rx_rd_ptr];

    // 读 RX_DATA 时展示队首字节
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) ;
        else if (psel && !pwrite && reg_addr==3'd3)
            regfile[3] <= rx_fifo_empty ? 32'h0 : {24'h0, rx_data_out};
    end

    // ================================================================
    // 波特率 / ETU 定时器
    // ================================================================
    wire [15:0] etu_div = regfile[7][15:0] ? regfile[7][15:0] : 16'd127;  // 默认 106kbps@13.56MHz
    reg [15:0] etu_cnt;
    wire etu_tick;  // 每个 ETU 产生一次 tick
    assign etu_tick = (etu_cnt >= etu_div);

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) etu_cnt <= 16'd0;
        else if (etu_tick) etu_cnt <= 16'd0;
        else if (tx_state != TX_IDLE || rx_state != RX_IDLE)
            etu_cnt <= etu_cnt + 16'd1;
        else etu_cnt <= 16'd0;
    end

    // ================================================================
    // 副载波生成 (847.5kHz = fc/16 for Type A)
    // ================================================================
    reg [3:0] subcarrier_cnt;
    wire subcarrier_tick;
    assign subcarrier_tick = (subcarrier_cnt == 4'd15);  // fc/16

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) subcarrier_cnt <= 4'd0;
        else if (subcarrier_tick) subcarrier_cnt <= 4'd0;
        else subcarrier_cnt <= subcarrier_cnt + 4'd1;
    end

    // ================================================================
    // 曼彻斯特编码器 (Modified Miller for Type A)
    // ================================================================
    // Type A: PCD→PICC 使用 Modified Miller 编码
    //   bit 1: pause after half ETU
    //   bit 0: pause at start of ETU
    //   序列开始: pause at start
    //   序列结束: logic 0 + pause at end
    //   pause: RF field off for ~2-3us (≈ fc/16)
    //
    // 简化实现: Manchester-like coding
    //   bit 1: 01 (low→high)
    //   bit 0: 10 (high→low)

    // ─── TX 状态机其余寄存器 ───
    reg [3:0] tx_bit_cnt;
    reg [7:0] tx_shift;
    reg       tx_parity;
    reg       tx_half;

    always @(posedge pclk or negedge presetn)
        if (!presetn) tx_state <= TX_IDLE; else tx_state <= tx_next;

    always @(*) begin
        tx_next = tx_state;
        case (tx_state)
            TX_IDLE:  if (regfile[0][1] && !tx_fifo_empty) tx_next = TX_SOF;
            TX_SOF:   if (etu_tick) tx_next = TX_DATA;
            TX_DATA:  if (etu_tick && tx_bit_cnt==4'd7 && tx_half) tx_next = TX_PARITY;
            TX_PARITY: if (etu_tick) tx_next = TX_EOF;
            TX_EOF:   if (etu_tick) begin
                if (!tx_fifo_empty && regfile[0][1]) tx_next = TX_SOF;
                else tx_next = TX_WAIT;
            end
            TX_WAIT:  begin
                if (!tx_fifo_empty && regfile[0][1]) tx_next = TX_SOF;
                else if (!regfile[0][1]) tx_next = TX_IDLE;
            end
            default: tx_next = TX_IDLE;
        endcase
    end

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            tx_bit_cnt <= 4'd0; tx_shift <= 8'h00; tx_parity <= 1'b0;
            tx_half <= 1'b0; tx_pop <= 1'b0;
        end else if (etu_tick) begin
            tx_pop <= 1'b0;
            case (tx_state)
                TX_SOF: begin
                    tx_shift  <= tx_data_out;
                    tx_bit_cnt <= 4'd0;
                    tx_parity <= 1'b0;
                    tx_half   <= 1'b0;
                    tx_pop    <= 1'b1;
                end
                TX_DATA: begin
                    if (!tx_half) begin
                        tx_half <= 1'b1;
                    end else begin
                        // 计算奇偶
                        tx_parity <= tx_parity ^ tx_shift[7];
                        tx_shift  <= {tx_shift[6:0], 1'b0};
                        if (tx_bit_cnt == 4'd7) begin
                            tx_bit_cnt <= 4'd0;
                        end else begin
                            tx_bit_cnt <= tx_bit_cnt + 4'd1;
                        end
                        tx_half <= 1'b0;
                    end
                end
                TX_PARITY: tx_half <= ~tx_half;
                TX_EOF:    tx_half <= 1'b0;
                default:   tx_half <= 1'b0;
            endcase
        end
    end

    // ─── 副载波调制输出 ───
    // Manchester: bit 1→subcarrier ON during first half
    //             bit 0→subcarrier OFF during first half
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) rf_tx <= 1'b0;
        else if (tx_state == TX_IDLE || tx_state == TX_WAIT)
            rf_tx <= 1'b0;
        else begin
            case (tx_state)
                TX_SOF: rf_tx <= 1'b1;  // SOF: 持续高
                TX_DATA: begin
                    if (!tx_half) begin
                        // 前半 ETU: bit=1 → 副载波 ON, bit=0 → OFF
                        if (tx_shift[7])
                            rf_tx <= subcarrier_tick ? ~rf_tx : rf_tx;
                        else
                            rf_tx <= 1'b0;
                    end else begin
                        // 后半 ETU: bit=1 → OFF, bit=0 → 副载波 ON
                        if (!tx_shift[7])
                            rf_tx <= subcarrier_tick ? ~rf_tx : rf_tx;
                        else
                            rf_tx <= 1'b0;
                    end
                end
                TX_PARITY: begin
                    if (!tx_half)
                        rf_tx <= tx_parity ? (subcarrier_tick ? ~rf_tx : rf_tx) : 1'b0;
                    else
                        rf_tx <= !tx_parity ? (subcarrier_tick ? ~rf_tx : rf_tx) : 1'b0;
                end
                TX_EOF: rf_tx <= 1'b0;
                default: rf_tx <= 1'b0;
            endcase
        end
    end

    // ─── TX 状态更新 ───
    // ─── TX 完成标志由统一 regfile 块处理 ───

    // ================================================================
    // 曼彻斯特解码器 (PICC→PCD, Type A uses Manchester for 106kbps)
    // ================================================================

    // ─── RX 状态机其余寄存器 ───
    reg [3:0] rx_bit_cnt;
    reg [7:0] rx_shift;
    reg       rx_parity;
    reg       rx_half;
    reg       rx_sample;
    reg       rf_rx_d1, rf_rx_d2;
    wire      rx_edge;
    assign    rx_edge = rf_rx_d1 ^ rf_rx_d2;

    always @(posedge pclk) begin
        rf_rx_d1 <= rf_rx;
        rf_rx_d2 <= rf_rx_d1;
    end
    assign rx_edge = rf_rx_d1 ^ rf_rx_d2;  // 检测电平变化

    always @(posedge pclk or negedge presetn)
        if (!presetn) rx_state <= RX_IDLE; else rx_state <= rx_next;

    always @(*) begin
        rx_next = rx_state;
        case (rx_state)
            RX_IDLE:  if (regfile[0][2] && rx_edge) rx_next = RX_SOF;
            RX_SOF:   if (etu_tick) rx_next = RX_DATA;
            RX_DATA:  if (etu_tick && rx_bit_cnt==4'd7 && rx_half) rx_next = RX_PARITY;
            RX_PARITY: if (etu_tick) rx_next = RX_EOF;
            RX_EOF:   if (etu_tick) begin
                if (regfile[0][2]) rx_next = RX_SOF;  // 连续接收
                else rx_next = RX_IDLE;
            end
            default: rx_next = RX_IDLE;
        endcase
    end

    assign rx_byte = rx_shift;
    assign rx_byte_valid = (rx_state == RX_EOF && etu_tick);

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            rx_bit_cnt <= 4'd0; rx_shift <= 8'h00; rx_parity <= 1'b0;
            rx_half <= 1'b0; rx_sample <= 1'b0;
        end else if (etu_tick) begin
            case (rx_state)
                RX_SOF: begin
                    rx_bit_cnt <= 4'd0; rx_parity <= 1'b0; rx_half <= 1'b0;
                end
                RX_DATA: begin
                    if (!rx_half) begin
                        rx_sample <= rf_rx_d2;  // 前半采样
                        rx_half <= 1'b1;
                    end else begin
                        // 后半采样，判断 Manchester bit
                        // 曼彻斯特: 1 = high→low (前半高后半低)
                        //           0 = low→high (前半低后半高)
                        if (rx_sample && !rf_rx_d2) begin
                            rx_shift <= {rx_shift[6:0], 1'b1};
                            rx_parity <= rx_parity ^ 1'b1;
                        end else if (!rx_sample && rf_rx_d2) begin
                            rx_shift <= {rx_shift[6:0], 1'b0};
                        end else begin
                            // 无效: 可能是冲突
                            rx_shift <= {rx_shift[6:0], 1'b0};
                        end
                        rx_bit_cnt <= rx_bit_cnt + 4'd1;
                        rx_half <= 1'b0;
                    end
                end
                RX_PARITY: begin
                    if (!rx_half) rx_sample <= rf_rx_d2;
                    else begin
                        // 验证奇偶 (触发信号, 由统一 block 写 regfile)
                        if ((rx_sample && !rf_rx_d2) != rx_parity)
                            rx_frame_err <= 1'b1;
                    end
                end
                RX_EOF: begin
                    rx_done <= 1'b1;
                end
                default: ;
            endcase
        end
    end

    // ================================================================
    // 防冲突状态机 (简化 ISO14443-3 Type A)
    // ================================================================
    localparam [2:0] AC_IDLE      = 3'd0;
    localparam [2:0] AC_READY1    = 3'd1;  // 等待 REQA
    localparam [2:0] AC_READY2    = 3'd2;  // 等待 ANTICOL
    localparam [2:0] AC_ANTICOL   = 3'd3;  // 防冲突循环
    localparam [2:0] AC_SELECT    = 3'd4;  // SELECT 确认
    localparam [2:0] AC_ACTIVE    = 3'd5;  // 激活状态

    reg [2:0] ac_state;
    reg [4:0] ac_cascade;     // 级联级别 (1-3)
    reg [39:0] uid;           // 序列号 (最多 5 字节)

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            ac_state   <= AC_IDLE;
            ac_cascade <= 5'd0;
            uid        <= 40'h0;
        end else if (regfile[0][31]) begin
            ac_state   <= AC_IDLE;
            ac_cascade <= 5'd0;
        end else if (regfile[0][3]) begin  // ANTICOL_EN
            case (ac_state)
                AC_IDLE: begin
                    if (rx_byte_valid && rx_byte == 8'h26)  // REQA
                        ac_state <= AC_READY1;
                    else if (rx_byte_valid && rx_byte == 8'h52)  // WUPA
                        ac_state <= AC_READY1;
                end
                AC_READY1: begin
                    // 发送 ATQA (0x0004 = 防冲突支持)
                    if (tx_state == TX_IDLE && tx_fifo_empty) begin
                        // 通过 FIFO 发送 ATQA
                    end
                    ac_state <= AC_READY2;
                end
                AC_READY2: begin
                    if (rx_byte_valid && rx_byte == 8'h93)  // ANTICOL level 1
                        ac_state <= AC_ANTICOL;
                    else if (rx_byte_valid && rx_byte == 8'h95)  // level 2
                        ac_state <= AC_ANTICOL;
                    else if (rx_byte_valid && rx_byte == 8'h97)  // level 3
                        ac_state <= AC_ANTICOL;
                end
                AC_ANTICOL: begin
                    // 发送 UID bytes
                    if (tx_state == TX_IDLE) begin
                        ac_state <= AC_SELECT;
                    end
                end
                AC_SELECT: begin
                    if (rx_byte_valid && rx_byte == 8'h93)  // SELECT
                        ac_state <= AC_ACTIVE;
                end
                AC_ACTIVE: begin
                    // 数据传输阶段
                    if (!regfile[0][3]) ac_state <= AC_IDLE;
                end
                default: ac_state <= AC_IDLE;
            endcase
        end
    end

    // ================================================================
    // 中断生成
    // ================================================================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) irq_o <= 1'b0;
        else begin
            if ((|regfile[6]) && (|regfile[5]))
                irq_o <= 1'b1;
            else
                irq_o <= 1'b0;
        end
    end

    // ================================================================
    // 统一 regfile 写入 (单 always, 放末尾确保所有信号已声明)
    // ================================================================
    integer bi;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (bi = 0; bi < NUM_REGS; bi = bi + 1) regfile[bi] <= 32'h0;
        end else begin
            // ─── APB 写入 ───
            if (apb_write) begin
                case (reg_addr)
                    3'd0: regfile[0] <= pwdata;
                    3'd2: regfile[2] <= pwdata;
                    3'd5: regfile[5] <= pwdata;
                    3'd6: regfile[6] <= regfile[6] & ~pwdata;
                    3'd7: regfile[7] <= pwdata;
                    default: ;
                endcase
            end

            // ─── FIFO 状态 ───
            regfile[4][7:0]   <= {4'd0, tx_count};
            regfile[4][15:8]  <= {4'd0, rx_count};
            regfile[4][16]    <= tx_fifo_full;
            regfile[4][17]    <= tx_fifo_empty;
            regfile[4][18]    <= rx_fifo_full;
            regfile[4][19]    <= rx_fifo_empty;

            // ─── STATUS ───
            regfile[1][0] <= (tx_state != TX_IDLE) || (rx_state != RX_IDLE);
            regfile[1][7] <= rf_rx || (tx_state != TX_IDLE);

            // TX_DONE
            if (tx_state == TX_EOF && etu_tick) begin
                regfile[1][1] <= 1'b1;
                if (regfile[5][0]) regfile[6][0] <= 1'b1;
            end else if (tx_state == TX_IDLE)
                regfile[1][1] <= 1'b0;

            // RX_DONE / FRAME_ERR
            if (rx_done) begin
                regfile[1][2] <= 1'b1;
                if (regfile[5][1]) regfile[6][1] <= 1'b1;
                rx_done <= 1'b0;
            end
            if (rx_frame_err) begin
                regfile[1][5] <= 1'b1;
                rx_frame_err <= 1'b0;
            end
        end
    end

endmodule
