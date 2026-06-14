// ============================================================================
// RV32EC CPU — PicoRV32 Wrapper with AHB-Lite Master Interface
// ============================================================================
// Wraps the open-source PicoRV32 (RV32IMC) configured as RV32EC:
//   - 16 registers (RV32E)
//   - Compressed ISA (C extension)
//   - IRQ support
//   - No MUL/DIV/COUNTERS (minimal area)
//
// PicoRV32 memory interface → AHB-Lite Master adapter
//
// License: ISC (same as PicoRV32)
// ============================================================================

`timescale 1ns / 1ps

module rv32ec_core (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         irq,
    output wire         sleep_req,
    output reg  [31:0]  haddr,
    output reg  [31:0]  hwdata,
    output reg          hwrite,
    output reg  [2:0]   hsize,
    output reg  [2:0]   hburst,
    output reg  [1:0]   htrans,
    output reg  [3:0]   hprot,
    output reg          hmastlock,
    input  wire [31:0]  hrdata,
    input  wire         hready,
    input  wire [1:0]   hresp
);

    // ================================================================
    // PicoRV32 Memory Interface (native)
    // ================================================================
    wire        mem_valid;
    wire        mem_instr;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    wire        mem_ready;
    wire [31:0] mem_rdata;
    wire        trap;

    // ================================================================
    // PicoRV32 Instance — RV32EC Configuration
    // ================================================================
    picorv32 #(
        .ENABLE_COUNTERS      (0),            // No performance counters
        .ENABLE_COUNTERS64    (0),
        .ENABLE_REGS_16_31    (0),            // RV32E: 16 registers only
        .ENABLE_REGS_DUALPORT (1),
        .TWO_STAGE_SHIFT      (1),
        .BARREL_SHIFTER       (0),
        .TWO_CYCLE_COMPARE    (0),
        .TWO_CYCLE_ALU        (0),
        .COMPRESSED_ISA       (1),            // C extension
        .CATCH_MISALIGN       (1),
        .CATCH_ILLINSN        (1),
        .ENABLE_PCPI          (0),            // No co-processor
        .ENABLE_MUL           (0),            // No multiply (RV32E)
        .ENABLE_FAST_MUL      (0),
        .ENABLE_DIV           (0),            // No divide (RV32E)
        .ENABLE_IRQ           (1),            // Interrupt support
        .ENABLE_IRQ_QREGS     (1),
        .ENABLE_IRQ_TIMER     (0),            // No internal timer
        .ENABLE_TRACE         (0),
        .REGS_INIT_ZERO       (1),
        .MASKED_IRQ           (32'h0000_0000),
        .LATCHED_IRQ          (32'hFFFF_FFFF),
        .PROGADDR_RESET       (32'h0000_0000),// Boot from ROM @ 0x00000000
        .PROGADDR_IRQ         (32'h0000_0010),// IRQ vector
        .STACKADDR            (32'h0001_1FFC) // Stack top (SRAM end - 4)
    ) u_picorv32 (
        .clk        (clk),
        .resetn     (rst_n),
        .trap       (trap),
        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_ready  (mem_ready),
        .mem_rdata  (mem_rdata),
        .irq        ({31'b0, irq}),  // IRQ on bit 0
        .eoi        ()
    );

    // ================================================================
    // PicoRV32 Memory → AHB-Lite Adapter
    // ================================================================

    assign mem_ready = hready;
    assign mem_rdata = hrdata;
    assign sleep_req = 1'b0;

    // AHB output drive
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            haddr     <= 32'h0;
            hwdata    <= 32'h0;
            hwrite    <= 1'b0;
            hsize     <= 3'b010;
            hburst    <= 3'b000;
            htrans    <= 2'b00;
            hprot     <= 4'b0011;
            hmastlock <= 1'b0;
        end else begin
            haddr     <= mem_addr;
            hwdata    <= mem_wdata;
            hwrite    <= |mem_wstrb;           // Any byte strobe = write
            hsize     <= 3'b010;               // 32-bit word
            hburst    <= 3'b000;               // SINGLE
            htrans    <= mem_valid ? 2'b10 : 2'b00;  // NONSEQ / IDLE
            hprot     <= 4'b0011;              // Data access
            hmastlock <= 1'b0;
        end
    end

endmodule
