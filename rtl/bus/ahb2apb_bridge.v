// ============================================================================
// AHB-Lite to APB Bridge — v2.0 重写版
// ============================================================================
// 设计要点:
//   - APB 地址/数据: 在 IDLE 检测到传输时寄存器捕获, SETUP/ACCESS 期间保持稳定
//   - APB psel/penable: 寄存器输出, 比数据晚 1 拍 (标准 APB 时序)
//   - hready: 寄存器输出, ACCESS 完成时拉高
//   - 从机应在 negedge pclk 采样写入 (确保寄存器输出已稳定)
//
// 版本: v2.0
// 负责人: 阿呆不呆
// ============================================================================

module ahb2apb_bridge (
    input  wire         hclk,
    input  wire         hresetn,

    // ─── AHB-Lite Slave Interface ───
    input  wire         hsel,
    input  wire [31:0]  haddr,
    input  wire [31:0]  hwdata,
    input  wire         hwrite,
    input  wire [2:0]   hsize,
    input  wire [2:0]   hburst,
    input  wire [1:0]   htrans,
    output wire [31:0]  hrdata,      // 组合逻辑
    output reg  [1:0]   hresp,

    // ─── APB Master Interface ───
    output wire         pclk,
    output wire         presetn,
    output wire         hready,      // 组合逻辑
    output wire         psel,        // 组合逻辑
    output wire         penable,     // 组合逻辑
    output wire [11:0]  paddr,       // 组合逻辑
    output wire         pwrite,      // 组合逻辑
    output wire [31:0]  pwdata,      // 组合逻辑
    input  wire [31:0]  prdata,
    input  wire         pready,
    input  wire         pslverr
);

    // ================================================================
    // 状态机
    // ================================================================
    localparam [1:0] IDLE   = 2'b00;
    localparam [1:0] SETUP  = 2'b01;
    localparam [1:0] ACCESS = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) state <= IDLE;
        else          state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (hsel && (htrans == 2'b10 || htrans == 2'b11))
                        next_state = SETUP;
            SETUP:  next_state = ACCESS;
            ACCESS: if (pready) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // ================================================================
    // APB 输出 — 全组合逻辑 (无寄存器延迟)
    //   paddr/pwdata/pwrite: 直接透传 AHB 信号 (AHB 协议保证传输期间稳定)
    //   psel/penable: 组合逻辑, 依赖 state
    // ================================================================
    wire apb_active;
    assign apb_active = (state == SETUP) || (state == ACCESS);
    assign psel    = apb_active;
    assign penable = (state == ACCESS);
    assign paddr   = apb_active ? haddr[13:2] : 12'h0;
    assign pwdata  = apb_active ? hwdata : 32'h0;
    assign pwrite  = apb_active ? hwrite : 1'b0;

    // ================================================================
    // 时钟和复位直通
    // ================================================================
    assign pclk    = hclk;
    assign presetn = hresetn;

    // ================================================================
    // AHB 响应
    //   hready: 组合逻辑 (立即响应)
    //   hrdata: 组合逻辑, ACCESS 期间 = prdata; 否则保持上次捕获值
    //   hresp:  寄存器输出
    // ================================================================
    
    assign hready = 
        (state == IDLE)  ? ((hsel && (htrans == 2'b10 || htrans == 2'b11)) ? 1'b0 : 1'b1) :
        (state == SETUP) ? 1'b0 :
        (state == ACCESS) ? pready :
                            1'b1;

    // ─── hrdata: 组合逻辑直通 (ACCESS 期间), negedge 锁存 (提前半拍) ───
    reg [31:0] hrdata_held;
    always @(negedge hclk or negedge hresetn) begin
        if (!hresetn)
            hrdata_held <= 32'h0;
        else if (state == ACCESS && pready)
            hrdata_held <= prdata;
    end

    assign hrdata = ((state == ACCESS) && pready) ? prdata : hrdata_held;

    // ─── hresp: 寄存器输出 ───
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            hresp  <= 2'b00;
        end else begin
            case (state)
                ACCESS: begin
                    if (pready)
                        hresp <= pslverr ? 2'b01 : 2'b00;
                end
                default: hresp <= 2'b00;
            endcase
        end
    end

endmodule
