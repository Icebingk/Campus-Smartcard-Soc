// ============================================================================
// ROM 模型 — 16KB 只读存储器（AHB Slave）
// ============================================================================
// 功能: 存储 boot code，CPU 从此启动
// 特点: 零等待周期、单端口读、字对齐访问
//
// 版本: v1.0
// 负责人: 阿呆不呆
// ============================================================================

module rom_model #(
    parameter ROM_SIZE = 16384,        // 16KB = 4096 words (32-bit)
    parameter ROM_ADDR_W = 12          // 14-bit byte addr → 12-bit word addr
) (
    // ─── AHB Slave Interface ───
    input  wire         hclk,
    input  wire         hresetn,
    input  wire         hsel,
    input  wire [31:0]  haddr,
    input  wire [31:0]  hwdata,        // ROM 忽略写
    input  wire         hwrite,
    input  wire [2:0]   hsize,
    input  wire [2:0]   hburst,
    input  wire [1:0]   htrans,
    output reg  [31:0]  hrdata,
    output wire         hready,
    output wire [1:0]   hresp
);

    // ─── ROM 存储数组 ───
    reg [31:0] rom_array [0:(ROM_SIZE/4)-1];

    // ─── 初始化 ROM 内容 ───
    initial begin
        // 这里可以从外部文件加载初始化代码
        // 或者硬编码一些简单的指令
        rom_array[0]     = 32'h00000001;  // boot code placeholder
        rom_array[1]     = 32'h00000002;
        // ... 更多初始化
    end

    // ─── 地址转换 ───
    wire [ROM_ADDR_W-1:0] rom_addr;
    assign rom_addr = haddr[ROM_ADDR_W+1:2];  // 字地址

    // ─── 读操作（组合逻辑）───
    always @(*) begin
        if (rom_addr < (ROM_SIZE/4)) begin
            hrdata = rom_array[rom_addr];
        end else begin
            hrdata = 32'hDEAD_BEEF;  // 越界读返回特征值
        end
    end

    // ─── 响应信号 ───
    assign hready = 1'b1;             // 零等待
    assign hresp  = 2'b00;            // OKAY（ROM 不返回 ERROR）

endmodule
