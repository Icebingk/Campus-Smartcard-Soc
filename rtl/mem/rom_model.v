// ============================================================================
// ROM 模型 — 16KB 只读存储器（AHB Slave）
// ============================================================================
// 功能: 存储 boot code，CPU 从此启动
// 特点: 零等待周期、单端口读、字对齐访问
//
// 版本: v1.0
// 负责人: 阿呆不呆
// ============================================================================

`timescale 1ns / 1ps

module rom_model #(
    parameter ROM_SIZE = 16384         // 16KB = 16384 bytes
) (
    // ─── AHB Slave Interface ───
    input  wire         hclk,
    input  wire         hresetn,
    input  wire         hsel,
    input  wire [31:0]  haddr,
    input  wire [31:0]  hwdata,        // ROM ignores writes
    input  wire         hwrite,
    input  wire [2:0]   hsize,
    input  wire [2:0]   hburst,
    input  wire [1:0]   htrans,
    output reg  [31:0]  hrdata,
    output wire         hready,
    output wire [1:0]   hresp
);

    // ─── ROM storage: byte-addressable (matches objcopy -O verilog output) ───
    reg [7:0] rom_array [0:ROM_SIZE-1];

    // ─── Load firmware ───
    initial begin
        $readmemh("../../fw/firmware.hex", rom_array);
        $display("[ROM] Firmware loaded (%0d bytes)", ROM_SIZE);
    end

    // ─── Read: assemble 4 bytes (little-endian) ───
    wire [13:0] byte_addr;
    assign byte_addr = haddr[13:0];

    always @(*) begin
        if (byte_addr < ROM_SIZE - 3) begin
            hrdata = {rom_array[byte_addr+3], rom_array[byte_addr+2],
                      rom_array[byte_addr+1], rom_array[byte_addr]};
        end else begin
            hrdata = 32'hDEAD_BEEF;
        end
    end

    // ─── Response ───
    assign hready = 1'b1;
    assign hresp  = 2'b00;

endmodule
