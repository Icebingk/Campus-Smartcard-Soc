// ============================================================================
// SRAM 模型 — 8KB 读写存储器（AHB Slave）
// ============================================================================
// 功能: 数据存储、堆栈、缓冲区
// 特点: 零等待周期、单端口读写、字对齐访问
//
// 版本: v1.0
// 负责人: 阿呆不呆
// ============================================================================

`timescale 1ns / 1ps

module sram_model #(
    parameter SRAM_SIZE = 8192,        // 8KB = 2048 words (32-bit)
    parameter SRAM_ADDR_W = 11         // 13-bit byte addr → 11-bit word addr
) (
    // ─── AHB Slave Interface ───
    input  wire         hclk,
    input  wire         hresetn,
    input  wire         hsel,
    input  wire [31:0]  haddr,
    input  wire [31:0]  hwdata,
    input  wire         hwrite,
    input  wire [2:0]   hsize,
    input  wire [2:0]   hburst,
    input  wire [1:0]   htrans,
    output reg  [31:0]  hrdata,
    output wire         hready,
    output wire [1:0]   hresp
);

    // ─── SRAM 存储数组 ───
    reg [31:0] sram_array [0:(SRAM_SIZE/4)-1];

    // ─── 初始化（可选，调试时清零）───
    integer i;
    initial begin
        for (i = 0; i < (SRAM_SIZE/4); i = i + 1) begin
            sram_array[i] = 32'h0000_0000;
        end
    end

    // ─── 地址转换 ───
    wire [SRAM_ADDR_W-1:0] sram_addr;
    assign sram_addr = haddr[SRAM_ADDR_W+1:2];  // 字地址

    // ─── 写操作（时序逻辑）───
    always @(posedge hclk) begin
        if (hsel && hwrite && (haddr[31:13] == 19'h00008)) begin
            // 字对齐写入（简化，不处理字节使能）
            sram_array[sram_addr] <= hwdata;
        end
    end

    // ─── 读操作（组合逻辑）───
    always @(*) begin
        if (sram_addr < (SRAM_SIZE/4)) begin
            hrdata = sram_array[sram_addr];
        end else begin
            hrdata = 32'hDEAD_BEEF;  // 越界读返回特征值
        end
    end

    // ─── 响应信号 ───
    assign hready = 1'b1;             // 零等待
    assign hresp  = 2'b00;            // OKAY

endmodule
