`timescale 1ns / 1ps
// ============================================================================
// EEPROM 控制器 — 行为级存根
// ============================================================================
// 功能: 片外 EEPROM 读写控制（I2C/SPI 接口）
//       本版本为 APB 寄存器存根，用于全芯片集成验证
//
// APB 基址: 0x4000_2000 (Slave 2)
// 寄存器数: 8 个 (0x000 ~ 0x01C)
//
// 版本: v0.1 (存根)
// 负责人: 阿呆不呆
// ============================================================================

module eep_top (
    // ─── APB Slave Interface ───
    input  wire         pclk,
    input  wire         presetn,
    input  wire         psel,
    input  wire         penable,
    input  wire [11:0]  paddr,
    input  wire         pwrite,
    input  wire [31:0]  pwdata,
    output reg  [31:0]  prdata,
    output wire         pready,
    output wire         pslverr,

    // ─── EEPROM 物理接口 (I2C) ───
    output wire         i2c_scl,       // I2C 时钟
    inout  wire         i2c_sda,       // I2C 数据

    // ─── 中断输出 ───
    output reg          irq_o           // 中断请求
);

    // ================================================================
    // 参数
    // ================================================================
    localparam NUM_REGS = 8;
    localparam ADDR_W   = 3;

    // ================================================================
    // 寄存器阵列
    // ================================================================
    reg [31:0] regfile [0:NUM_REGS-1];

    // ─── 寄存器地址映射 ───
    // 0x00: EEP_CTRL        控制（使能、读写模式、启动）
    // 0x04: EEP_STATUS      状态（忙、完成、错误）
    // 0x08: EEP_ADDR        EEPROM 内部地址
    // 0x0C: EEP_WDATA      写数据
    // 0x10: EEP_RDATA      读数据
    // 0x14: EEP_DIV         时钟分频（I2C 速率）
    // 0x18: EEP_INT_EN      中断使能
    // 0x1C: EEP_INT_STATUS  中断状态

    wire [ADDR_W-1:0] reg_addr;
    assign reg_addr = paddr[ADDR_W-1:0];  // 字地址, 8 寄存器 = paddr[2:0]

    // ================================================================
    // APB 写操作 (negedge 采样, 等待 Bridge 寄存器输出稳定)
    // ================================================================
    wire apb_write;
    assign apb_write = psel && penable && pwrite;

    integer i;
    always @(negedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                regfile[i] <= 32'h0000_0000;
            end
        end else if (apb_write && (reg_addr < NUM_REGS)) begin
            regfile[reg_addr] <= pwdata;
        end
    end

    // ================================================================
    // APB 读操作 (psel 有效即输出, 不等 penable)
    // ================================================================
    always @(*) begin
        if (psel && !pwrite) begin
            if (reg_addr < NUM_REGS)
                prdata = regfile[reg_addr];
            else
                prdata = 32'hDEAD_BEEF;
        end else begin
            prdata = 32'h0;
        end
    end

    // ================================================================
    // APB 响应
    // ================================================================
    assign pready  = 1'b1;
    assign pslverr = (psel && penable && (reg_addr >= NUM_REGS));

    // ================================================================
    // I2C 接口（存根：弱上拉）
    // ================================================================
    assign i2c_scl = 1'bz;   // 高阻，外部上拉
    assign i2c_sda = 1'bz;

    // ================================================================
    // 中断逻辑（存根）
    // ================================================================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            irq_o <= 1'b0;
        end else begin
            if (regfile[6][0] && regfile[0][0]) begin
                irq_o <= 1'b1;
                regfile[7][0] <= 1'b1;
                regfile[1][0] <= 1'b1;   // STATUS[0]=done
            end else begin
                irq_o <= 1'b0;
            end
        end
    end

endmodule
