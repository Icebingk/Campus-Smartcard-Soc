// ============================================================================
// PMU (Power Management Unit) — 系统电源管理
// ============================================================================
// 功能: 时钟门控、复位分发、低功耗控制
// 版本: v1.0（存根，待梁芷晴完善物理设计阶段）
//
// 负责人: 陆凤敏
// ============================================================================

module pmu (
    input  wire         clk_sys,        // 系统主时钟
    input  wire         rst_n,          // 系统复位
    
    // ─── CPU 时钟门控 ───
    input  wire         cpu_clk_en,
    output wire         cpu_clk_gated,
    
    // ─── AES 时钟门控 ───
    input  wire         aes_clk_en,
    output wire         aes_clk_gated,
    
    // ─── 基带时钟门控 ───
    input  wire         bb_clk_en,
    output wire         bb_clk_gated,
    
    // ─── 复位同步释放 ───
    output wire         rst_sync_n,
    
    // ─── 低功耗模式 ───
    input  wire         sleep_en,       // 进入休眠
    output wire         sleep_ack       // 休眠确认
);

    // ================================================================
    // 时钟门控实现（简化版，实际需 ICG cell）
    // ================================================================
    
    assign cpu_clk_gated = clk_sys & cpu_clk_en;
    assign aes_clk_gated = clk_sys & aes_clk_en;
    assign bb_clk_gated  = clk_sys & bb_clk_en;

    // ================================================================
    // 复位同步释放（2-stage DFF）
    // ================================================================
    
    reg [1:0] rst_sync_chain;
    
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            rst_sync_chain <= 2'b00;
        end else begin
            rst_sync_chain <= {rst_sync_chain[0], 1'b1};
        end
    end
    
    assign rst_sync_n = rst_sync_chain[1];

    // ================================================================
    // 低功耗控制（待实现）
    // ================================================================
    
    assign sleep_ack = sleep_en;  // 简单回路

endmodule
