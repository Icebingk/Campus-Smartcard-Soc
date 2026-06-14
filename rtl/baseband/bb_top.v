`timescale 1ns / 1ps
// ============================================================================
// 数字基带 (Digital Baseband) — 行为级存根
// ============================================================================
// 功能: ISO14443 Type A 协议处理、防冲突 FSM、曼彻斯特编解码
//       本版本为 APB 寄存器存根，用于全芯片集成验证
//
// APB 基址: 0x4000_0000 (Slave 0)
// 寄存器数: 8 个 (0x000 ~ 0x01C)
//
// 版本: v0.1 (存根，待林子轩完善)
// 负责人: 林子轩 (存根由阿呆不呆提供)
// ============================================================================

module bb_top (
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

    // ─── 射频接口 ───
    input  wire         rf_rx,         // 射频接收
    output reg          rf_tx,         // 射频发送
    input  wire         rf_clk,        // 射频时钟

    // ─── 中断输出 ───
    output reg          irq_o           // 中断请求
);

    // ================================================================
    // 参数
    // ================================================================
    localparam NUM_REGS = 8;           // 8 个寄存器
    localparam ADDR_W   = 3;           // log2(8)

    // ================================================================
    // 寄存器阵列
    // ================================================================
    reg [31:0] regfile [0:NUM_REGS-1];

    // ─── 寄存器地址映射 ───
    // 0x00: BB_CTRL       控制寄存器
    // 0x04: BB_STATUS     状态寄存器
    // 0x08: BB_TX_DATA    发送数据
    // 0x0C: BB_RX_DATA    接收数据
    // 0x10: BB_FIFO_LEVEL FIFO 水位
    // 0x14: BB_INT_EN     中断使能
    // 0x18: BB_INT_STATUS 中断状态
    // 0x1C: BB_BAUD_CFG   波特率配置

    wire [ADDR_W-1:0] reg_addr;
    assign reg_addr = paddr[ADDR_W+1:2];  // 字地址

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
    // APB 读操作 (psel 有效即输出, 不等 penable, 确保 Bridge 捕获窗口内数据稳定)
    // ================================================================
    always @(*) begin
        if (psel && !pwrite) begin
            if (reg_addr < NUM_REGS) begin
                prdata = regfile[reg_addr];
            end else begin
                prdata = 32'hDEAD_BEEF;
            end
        end else begin
            prdata = 32'h0;
        end
    end

    // ================================================================
    // APB 响应
    // ================================================================
    assign pready  = 1'b1;    // 零等待
    assign pslverr = (psel && penable && (reg_addr >= NUM_REGS));

    // ================================================================
    // 射频接口（存根：回环）
    // ================================================================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            rf_tx <= 1'b0;
        else
            rf_tx <= rf_rx;   // 简单回环，便于测试
    end

    // ================================================================
    // 中断逻辑（存根：基于控制寄存器 bit0 触发）
    // ================================================================
    wire int_en;
    assign int_en = regfile[5][0];  // BB_INT_EN[0]

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            irq_o <= 1'b0;
        end else begin
            // 简单中断模型：当控制寄存器 bit0 为 1 且中断使能时，产生中断
            if (int_en && regfile[0][0]) begin
                irq_o <= 1'b1;
                regfile[6][0] <= 1'b1;  // BB_INT_STATUS[0] 置位
            end else begin
                irq_o <= 1'b0;
            end
        end
    end

endmodule
