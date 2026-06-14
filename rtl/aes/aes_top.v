`timescale 1ns / 1ps
// ============================================================================
// AES-128 协处理器 — 行为级存根
// ============================================================================
// 功能: 迭代折叠架构 AES-128 加密/解密引擎
//       本版本为 APB 寄存器存根，用于全芯片集成验证
//
// APB 基址: 0x4000_1000 (Slave 1)
// 寄存器数: 16 个 (0x000 ~ 0x03C)
//
// 版本: v0.1 (存根，待梁芷晴完善)
// 负责人: 梁芷晴 (存根由阿呆不呆提供)
// ============================================================================

module aes_top (
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

    // ─── 中断输出 ───
    output reg          irq_o           // 中断请求
);

    // ================================================================
    // 参数
    // ================================================================
    localparam NUM_REGS = 16;          // 16 个寄存器
    localparam ADDR_W   = 4;           // log2(16)

    // ================================================================
    // 寄存器阵列
    // ================================================================
    reg [31:0] regfile [0:NUM_REGS-1];

    // ─── 寄存器地址映射 (per memory_map.md) ───
    // 0x00: AES_CTRL      控制（模式、启动）
    // 0x04: AES_STATUS    状态（忙、完成）
    // 0x08: AES_KEY0      密钥 [31:0]
    // 0x0C: AES_KEY1      密钥 [63:32]
    // 0x10: AES_KEY2      密钥 [95:64]
    // 0x14: AES_KEY3      密钥 [127:96]
    // 0x18: AES_DIN0      明文/密文输入 [31:0]
    // 0x1C: AES_DIN1      明文/密文输入 [63:32]
    // 0x20: AES_DIN2      明文/密文输入 [95:64]
    // 0x24: AES_DIN3      明文/密文输入 [127:96]
    // 0x28: AES_DOUT0     密文/明文输出 [31:0]
    // 0x2C: AES_DOUT1     密文/明文输出 [63:32]
    // 0x30: AES_DOUT2     密文/明文输出 [95:64]
    // 0x34: AES_DOUT3     密文/明文输出 [127:96]
    // 0x38: AES_INT_EN    中断使能
    // 0x3C: AES_INT_STATUS 中断状态

    wire [ADDR_W-1:0] reg_addr;
    assign reg_addr = paddr[ADDR_W-1:0];  // 字地址, 16 寄存器 = paddr[3:0]

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
        end else if (apb_write) begin
            regfile[reg_addr] <= pwdata;
        end
    end

    // ================================================================
    // APB 读操作 (psel 有效即输出, 不等 penable)
    // ================================================================
    always @(*) begin
        if (psel && !pwrite) begin
            prdata = regfile[reg_addr];
        end else begin
            prdata = 32'h0;
        end
    end

    // ================================================================
    // APB 响应
    // ================================================================
    assign pready  = 1'b1;
    assign pslverr = 1'b0;

    // ================================================================
    // 中断逻辑（存根）
    // ================================================================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            irq_o <= 1'b0;
        end else begin
            // CTRL[0]=启动, INT_EN[0]=中断使能
            if (regfile[14][0] && regfile[0][0]) begin
                irq_o <= 1'b1;
                regfile[15][0] <= 1'b1;  // INT_STATUS[0] 置位
                regfile[1][0]  <= 1'b1;  // STATUS[0]=done
            end else begin
                irq_o <= 1'b0;
            end
        end
    end

endmodule
