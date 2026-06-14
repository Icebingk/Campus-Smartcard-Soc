// ============================================================================
// AHB Master Bus Functional Model (BFM)
// ============================================================================
// 功能: 仿真中代替 CPU 产生 AHB 读写操作
// 用法: 在 Testbench 中调用其 task 完成指定地址的读写
//
// 版本: v1.0
// 负责人: 阿呆不呆
// ============================================================================

module ahb_master_bfm (
    // ─── 时钟与复位 ───
    input  wire         hclk,
    input  wire         hresetn,

    // ─── AHB Master Interface（连接到总线矩阵）───
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
    // 初始化
    // ================================================================
    initial begin
        haddr    = 32'h0;
        hwdata   = 32'h0;
        hwrite   = 1'b0;
        hsize    = 3'b010;  // 32-bit
        hburst   = 3'b000;  // SINGLE
        htrans   = 2'b00;   // IDLE
        hprot    = 4'h0;
        hmastlock= 1'b0;
    end

    // ================================================================
    // Task: 单次读操作
    // ================================================================
    task read_word;
        input  [31:0] addr;
        output [31:0] data;
        begin
            // 第一拍: 发起 NONSEQ 读
            @(posedge hclk);
            haddr   = addr;
            hwrite  = 1'b0;     // 读操作
            hsize   = 3'b010;   // 32-bit
            hburst  = 3'b000;   // SINGLE
            htrans  = 2'b10;    // NONSEQ

            // 等待 hready
            wait_ready();

            // 第二拍: 结果有效，读取 hrdata
            @(posedge hclk);
            data = hrdata;

            // 返回 IDLE
            htrans = 2'b00;
            @(posedge hclk);
        end
    endtask

    // ================================================================
    // Task: 单次写操作
    // ================================================================
    task write_word;
        input  [31:0] addr;
        input  [31:0] data;
        begin
            // 第一拍: 发起 NONSEQ 写
            @(posedge hclk);
            haddr   = addr;
            hwdata  = data;
            hwrite  = 1'b1;     // 写操作
            hsize   = 3'b010;   // 32-bit
            hburst  = 3'b000;   // SINGLE
            htrans  = 2'b10;    // NONSEQ

            // 等待 hready
            wait_ready();

            // 返回 IDLE
            @(posedge hclk);
            htrans = 2'b00;
            @(posedge hclk);
        end
    endtask

    // ================================================================
    // Task: 等待 hready
    // ================================================================
    task wait_ready;
        begin
            while (~hready) begin
                @(posedge hclk);
            end
        end
    endtask

    // ================================================================
    // Task: 延迟若干周期
    // ================================================================
    task delay_cycles;
        input [31:0] num_cycles;
        integer i;
        begin
            for (i = 0; i < num_cycles; i = i + 1) begin
                @(posedge hclk);
            end
        end
    endtask

endmodule
