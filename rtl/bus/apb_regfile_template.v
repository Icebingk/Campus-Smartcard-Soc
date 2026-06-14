// ============================================================================
// APB 寄存器文件 — 通用模板
// 适用于: 数字基带、AES、EEPROM 控制器、系统控制等所有 APB 外设
// 版本: v1.0 — 阿呆不呆
//
// 使用说明:
//   1. 修改 REGFILE_NUM_REGS 为你需要的寄存器数量
//   2. 在 regfile 数组初始化区定义每个寄存器的默认值
//   3. 在"自定义寄存器逻辑"区域添加模块特定的读写行为
//   4. 将本文件内容合并到你的模块顶层 (不建议直接例化)
// ============================================================================

module apb_regfile_template #(
    parameter REGFILE_NUM_REGS = 16,        // 寄存器个数
    parameter REGFILE_ADDR_W  = 4           // 地址位宽 = log2(NUM_REGS)
) (
    // ─── APB Slave Interface ───
    input  wire                    pclk,
    input  wire                    presetn,
    input  wire                    psel,
    input  wire                    penable,
    input  wire [REGFILE_ADDR_W-1:0] paddr,  // 字地址 (4-byte aligned)
    input  wire                    pwrite,
    input  wire [31:0]             pwdata,
    output reg  [31:0]             prdata,
    output wire                    pready,
    output wire                    pslverr,

    // ─── 自定义硬件接口 (模块开发者自定义) ───
    // 示例: 连接到模块内部逻辑的信号
    output reg  [31:0]             hw_ctrl,     // 控制信号输出
    input  wire [31:0]             hw_status,   // 状态输入
    input  wire [31:0]             hw_data_in   // 数据输入
);

    // ================================================================
    // 寄存器阵列（写入 APB，读出返回 prdata）
    // ================================================================
    reg [31:0] regfile [0:REGFILE_NUM_REGS-1];

    // ─── 地址对齐检查 ───
    localparam ADDR_W = REGFILE_ADDR_W;
    wire [ADDR_W-1:0] reg_addr;
    assign reg_addr = paddr[ADDR_W-1+2:2];  // 字地址 (忽略 byte offset [1:0])

    // ================================================================
    // APB 写操作 (Setup + Access 两周期)
    // ================================================================
    wire apb_write;
    assign apb_write = psel && penable && pwrite;

    // ─── 寄存器写（带地址越界保护）───
    integer i;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (i = 0; i < REGFILE_NUM_REGS; i = i + 1) begin
                regfile[i] <= 32'h0000_0000;
            end
        end else if (apb_write && (reg_addr < REGFILE_NUM_REGS)) begin
            regfile[reg_addr] <= pwdata;
        end
    end

    // ================================================================
    // APB 读操作
    // ================================================================
    always @(*) begin
        if (psel && penable && !pwrite) begin
            if (reg_addr < REGFILE_NUM_REGS) begin
                prdata = regfile[reg_addr];
            end else begin
                prdata = 32'hDEAD_BEEF;  // 越界读返回特征值
            end
        end else begin
            prdata = 32'h0;
        end
    end

    // ================================================================
    // APB 响应信号
    // ================================================================
    assign pready  = 1'b1;   // 零等待（如需等待，可改为状态机）
    assign pslverr = (psel && penable && (reg_addr >= REGFILE_NUM_REGS));

    // ================================================================
    // 自定义寄存器逻辑（模块开发者在此扩展）
    // ================================================================
    
    // 示例: 将 regfile[0] 映射到 hw_ctrl 输出
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            hw_ctrl <= 32'h0;
        else
            hw_ctrl <= regfile[0];  // 控制寄存器 → 硬件输出
    end

    // 示例: 将硬件状态读入映射到 regfile（只读寄存器用 wire 覆盖）
    // 方法: 在 APB 读逻辑中使用 hw_status 替代 regfile[1]

endmodule
