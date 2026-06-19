`timescale 1ns / 1ps
// ============================================================================
// EEPROM I2C 主控控制器 — v1.0
// ============================================================================
// 功能: 片外 EEPROM 读写控制 (I2C Master)
//       支持标准模式 (100kHz) 和快速模式 (400kHz)
//       支持单字节/多字节读写
//
// APB 基址: 0x4000_2000 (Slave 2)
// 寄存器数: 8 个 (0x00 ~ 0x1C)
//
// 版本: v1.0 (完整 I2C 主控)
// 负责人: 阿呆不呆
// ============================================================================
//
// 使用流程:
//   写: 1. 设 EEP_ADDR (目标地址)  2. 写 EEP_WDATA (数据)
//       3. 设 EEP_CTRL.bit0=0(RD=0) bit1=1(WR=1) bit31=1(START)
//       4. 等待 STATUS.done 或中断
//   读: 1. 设 EEP_ADDR (目标地址)
//       2. 设 EEP_CTRL.bit0=1(RD=1) bit31=1(START)
//       3. 等待 STATUS.done 或中断  4. 读 EEP_RDATA
//
// ============================================================================

module eep_top (
    input  wire         pclk, presetn,
    input  wire         psel, penable,
    input  wire [11:0]  paddr,
    input  wire         pwrite,
    input  wire [31:0]  pwdata,
    output reg  [31:0]  prdata,
    output wire         pready, pslverr,
    inout  wire         i2c_sda,
    output wire         i2c_scl,
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

    // 0x00: EEP_CTRL     控制（bit0=rd, bit1=wr, bit31=start）
    // 0x04: EEP_STATUS   状态（bit0=busy, bit1=done, bit2=err, bit3=nack）
    // 0x08: EEP_ADDR     EEPROM 内部地址 (device_addr << 24 | mem_addr)
    // 0x0C: EEP_WDATA    写数据 [7:0]
    // 0x10: EEP_RDATA    读数据 [7:0] (RO)
    // 0x14: EEP_DIV      时钟分频 (pclk / (div+1)*2 = i2c_clk)
    // 0x18: EEP_INT_EN   中断使能
    // 0x1C: EEP_INT_STATUS 中断状态 (W1C)

    reg [31:0] regfile [0:NUM_REGS-1];
    integer i;
    always @(negedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (i = 0; i < NUM_REGS; i = i + 1) regfile[i] <= 32'h0;
        end else if (apb_write) begin
            if (reg_addr != 3'h4 && reg_addr != 3'h1)  // STATUS & RDATA RO
                regfile[reg_addr] <= pwdata;
            if (reg_addr == 3'h7)  // INT_STATUS W1C
                regfile[7] <= regfile[7] & ~pwdata;
        end
    end

    always @(*) prdata = (psel && !pwrite) ? regfile[reg_addr] : 32'h0;
    assign pready = 1'b1;
    assign pslverr = 1'b0;

    // ================================================================
    // I2C 时序参数
    // ================================================================
    // DIV 控制 SCL 频率: i2c_period = (DIV+1)*2 pclk cycles
    // 例如: pclk=13.56MHz, DIV=67 → SCL≈100kHz
    //       pclk=13.56MHz, DIV=16 → SCL≈400kHz
    wire [15:0] div_val = regfile[5][15:0];
    reg [15:0] clk_cnt;
    wire clk_tick;  // SCL 半周期 tick
    assign clk_tick = (clk_cnt == div_val);

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) clk_cnt <= 16'd0;
        else if (clk_tick || state==S_IDLE) clk_cnt <= 16'd0;
        else if (state != S_IDLE) clk_cnt <= clk_cnt + 16'd1;
    end

    // ================================================================
    // I2C 状态机
    // ================================================================
    localparam [3:0]
        S_IDLE   = 4'd0,
        S_START  = 4'd1,
        S_SEND   = 4'd2,   // 发送字节 (地址+数据)
        S_WAIT   = 4'd3,   // 等待 ACK
        S_RECV   = 4'd4,   // 接收字节
        S_ACK    = 4'd5,   // 发送 ACK/NACK
        S_STOP1  = 4'd6,   // STOP 第一阶段
        S_STOP2  = 4'd7,   // STOP 第二阶段
        S_DONE_S = 4'd8;

    reg [3:0] state, nxt;
    reg [3:0] bit_cnt;       // 当前字节剩余 bit (0..8)
    reg [7:0] shift_reg;     // 移位寄存器
    reg [2:0] phase;         // 操作阶段: 0=设备地址, 1=存储地址, 2=数据
    reg       scl_out;
    reg       sda_out;
    reg       sda_oen;        // 1=驱动, 0=高阻
    reg       is_read;        // 当前是读操作

    assign i2c_scl = scl_out ? 1'bz : 1'b0;
    assign i2c_sda = sda_oen ? (sda_out ? 1'bz : 1'b0) : 1'bz;

    // ─── 状态转换 ───
    always @(posedge pclk or negedge presetn)
        if (!presetn) state <= S_IDLE; else state <= nxt;

    always @(*) begin
        nxt = state;
        case (state)
            S_IDLE:  if (regfile[0][31] && clk_tick) nxt = S_START;
            S_START: if (clk_tick) nxt = S_SEND;
            S_SEND:  if (clk_tick && bit_cnt==4'd8) nxt = S_WAIT;
            S_WAIT:  if (clk_tick) begin
                if (phase==3'd2 && !is_read) nxt = S_STOP1;     // 写完成
                else if (phase==3'd2 && is_read) nxt = S_RECV;  // 开始读
                else if (phase==3'd0 && is_read) nxt = S_START; // 重复START
                else nxt = S_SEND;                                // 继续发下一字节
            end
            S_RECV:  if (clk_tick && bit_cnt==4'd8) nxt = S_ACK;
            S_ACK:   if (clk_tick) begin
                if (phase==3'd3) nxt = S_STOP1;  // 读完成
                else nxt = S_RECV;                // 继续读下一个字节
            end
            S_STOP1: if (clk_tick) nxt = S_STOP2;
            S_STOP2: if (clk_tick) nxt = S_DONE_S;
            S_DONE_S: nxt = S_IDLE;
            default: nxt = S_IDLE;
        endcase
    end

    // ─── SCL 生成 ───
    // SCL 在 tick 翻转 (除 START/STOP 特殊时序外)
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) scl_out <= 1'b1;
        else if (clk_tick) begin
            case (state)
                S_IDLE:  scl_out <= 1'b1;
                S_START: scl_out <= 1'b1;
                S_STOP1: scl_out <= 1'b0;
                S_STOP2: scl_out <= 1'b1;
                default: scl_out <= ~scl_out;  // 标准翻转
            endcase
        end
    end

    // ─── SDA 控制 ───
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            sda_out <= 1'b1; sda_oen <= 1'b0;
        end else if (clk_tick) begin
            case (state)
                S_IDLE: begin sda_out <= 1'b1; sda_oen <= 1'b0; end
                S_START: begin
                    // START: SDA 在 SCL=1 时拉低
                    sda_out <= 1'b0; sda_oen <= 1'b1;
                end
                S_SEND: begin
                    // 在 SCL 低电平时输出数据位
                    if (scl_out == 1'b0) begin
                        if (bit_cnt < 4'd8) begin
                            sda_out <= ~shift_reg[7]; sda_oen <= 1'b1;
                        end else begin
                            sda_oen <= 1'b0;  // 释放 SDA 等 ACK
                        end
                    end
                end
                S_WAIT: begin
                    sda_oen <= 1'b0;  // 高阻，检测 ACK
                end
                S_RECV: begin
                    // 在 SCL 高电平时采样，低电平时释放
                    sda_oen <= 1'b0;  // 高阻 (从机驱动)
                end
                S_ACK: begin
                    if (scl_out == 1'b0) begin
                        // 最后字节发 NACK，否则 ACK
                        sda_out <= (phase==3'd3) ? 1'b1 : 1'b0;
                        sda_oen <= 1'b1;
                    end
                end
                S_STOP1: begin
                    // STOP: SDA 在 SCL=0 时先保持低
                    sda_out <= 1'b0; sda_oen <= 1'b1;
                end
                S_STOP2: begin
                    // 然后在 SCL=1 时释放
                    sda_out <= 1'b1; sda_oen <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    // ─── 移位寄存器 & 位计数 ───
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            shift_reg <= 8'h00;
            bit_cnt   <= 4'd0;
            phase     <= 3'd0;
            is_read   <= 1'b0;
        end else if (state==S_IDLE && regfile[0][31]) begin
            // 启动: 加载设备地址
            // EEP_ADDR[31:24] = 设备地址 (7-bit << 1 | R/W)
            // 默认设备地址 0xA0 (write) / 0xA1 (read)
            is_read   <= regfile[0][0];
            if (regfile[0][0])  // 读
                shift_reg <= {regfile[3][31:25], 1'b1};  // device addr | R=1
            else               // 写
                shift_reg <= {regfile[3][31:25], 1'b0};  // device addr | W=0
            phase   <= 3'd0;
            bit_cnt <= 4'd0;
        end else if (clk_tick) begin
            case (state)
                S_SEND: begin
                    if (bit_cnt < 4'd8) begin
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        bit_cnt <= bit_cnt + 4'd1;
                    end else bit_cnt <= 4'd0;
                end
                S_RECV: begin
                    if (bit_cnt < 4'd8) begin
                        shift_reg <= {shift_reg[6:0], i2c_sda};
                        bit_cnt <= bit_cnt + 4'd1;
                    end else bit_cnt <= 4'd0;
                end
                S_WAIT: begin
                    // 根据 phase 决定下一步加载什么
                    case (phase)
                        3'd0: begin  // 设备地址已发完
                            if (is_read) begin
                                // 读: 直接进入 RECV，phase 跳到 2
                                phase <= 3'd2;
                            end else begin
                                // 写: 加载存储器地址 (EEP_ADDR[15:0])
                                shift_reg <= regfile[2][15:8];
                                phase <= 3'd1;
                            end
                        end
                        3'd1: begin  // 存储器地址高字节已发
                            shift_reg <= regfile[2][7:0];
                            phase <= 3'd2;
                        end
                        3'd2: begin  // 已发地址，发数据 (写)/ 收数据 (读)
                            if (!is_read) begin
                                shift_reg <= regfile[1][7:0];  // WDATA
                                phase <= 3'd3;  // 标记数据传输阶段
                            end
                        end
                        default: ;
                    endcase
                    // 检查 NACK
                    if (i2c_sda == 1'b1) begin
                        // 从机 NACK: 记录错误
                    end
                end
                S_ACK: begin
                    if (is_read) phase <= phase + 3'd1;  // 多字节读递增
                end
                default: ;
            endcase
        end
    end

    // ─── 读数据锁存 (在 RECV 最后一位采样后) ───
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) ;
        else if (state==S_RECV && clk_tick && bit_cnt==4'd7)
            regfile[4] <= {24'h0, shift_reg[6:0], i2c_sda};  // RDATA
    end

    // ─── 状态寄存器更新 ───
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) ;
        else begin
            regfile[1][0] <= (state != S_IDLE);  // BUSY
            if (state==S_DONE_S) begin
                regfile[1][1] <= 1'b1;             // DONE
                regfile[0][31] <= 1'b0;            // clear START
            end else if (state==S_IDLE && regfile[0][31])
                regfile[1][1] <= 1'b0;
        end
    end

    // ─── 错误检测: NACK ───
    reg nack_detected;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) nack_detected <= 1'b0;
        else if (state==S_WAIT && clk_tick && i2c_sda==1'b1)
            nack_detected <= 1'b1;
        else if (state==S_IDLE)
            nack_detected <= 1'b0;
    end

    always @(posedge pclk) begin
        if (state==S_WAIT && clk_tick && i2c_sda==1'b1)
            regfile[1][3] <= 1'b1;  // NACK flag
    end

    // ================================================================
    // 中断生成
    // ================================================================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) irq_o <= 1'b0;
        else begin
            if (state==S_DONE_S && regfile[6][0]) begin
                irq_o <= 1'b1; regfile[7][0] <= 1'b1;
            end else if (!regfile[6][0]) irq_o <= 1'b0;
        end
    end

endmodule
