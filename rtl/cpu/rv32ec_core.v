`timescale 1ns / 1ps
// ============================================================================
// RV32EC CPU — 行为级模型 (Behavioral Stub)
// ============================================================================
// 功能: 仿真中代替真实 RISC-V 核心，通过 AHB Master 接口访问总线
//       启动后自动执行一组读写测试序列，验证全芯片互联
//
// 接口: AHB-Lite Master + 中断输入 + 休眠控制
//
// 版本: v1.0 (存根，待替换为真实 RV32EC 核)
// 负责人: 阿呆不呆
// ============================================================================

module rv32ec_core (
    // ─── 时钟与复位 ───
    input  wire         clk,
    input  wire         rst_n,

    // ─── 中断 ───
    input  wire         irq,           // 外部中断 (基带/AES/EEPROM 聚合)

    // ─── 休眠控制 ───
    output wire         sleep_req,     // 休眠请求

    // ─── AHB-Lite Master Interface ───
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
        haddr     = 32'h0;
        hwdata    = 32'h0;
        hwrite    = 1'b0;
        hsize     = 3'b010;   // 32-bit
        hburst    = 3'b000;   // SINGLE
        htrans    = 2'b00;    // IDLE
        hprot     = 4'h0;
        hmastlock = 1'b0;
    end

    // ─── 休眠控制（暂时不用）───
    assign sleep_req = 1'b0;

    // ================================================================
    // 内部 Task: 等待 hready (先等一拍让 Bridge 采样, 再检查)
    // ================================================================
    task wait_ready;
        begin
            @(posedge clk);      // 先等一拍，让 Bridge 采样 htrans
            while (~hready) begin
                @(posedge clk);
            end
        end
    endtask

    // ================================================================
    // 内部 Task: AHB 读操作 (先设信号, 再等时钟沿, 匹配硬件 setup 时序)
    // ================================================================
    task read_word;
        input  [31:0] addr;
        output [31:0] data;
        begin
            haddr   = addr;
            hwrite  = 1'b0;
            hsize   = 3'b010;
            hburst  = 3'b000;
            htrans  = 2'b10;    // NONSEQ
            @(posedge clk);      // Bridge 在此沿采样
            wait_ready();        // 等待 hready
            @(posedge clk);      // 下一拍 hrdata 有效
            data = hrdata;
            htrans = 2'b00;
            @(posedge clk);
        end
    endtask

    // ================================================================
    // 内部 Task: AHB 写操作
    // ================================================================
    task write_word;
        input [31:0] addr;
        input [31:0] data;
        begin
            haddr   = addr;
            hwdata  = data;
            hwrite  = 1'b1;
            hsize   = 3'b010;
            hburst  = 3'b000;
            htrans  = 2'b10;    // NONSEQ
            @(posedge clk);      // Bridge 在此沿采样
            wait_ready();
            htrans = 2'b00;
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    // ================================================================
    // 内部 Task: 延迟
    // ================================================================
    task delay;
        input [31:0] cycles;
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1) begin
                @(posedge clk);
            end
        end
    endtask

    // ================================================================
    // 主测试序列 — 上电自检 & 全外设遍历
    // ================================================================
    reg [31:0] rdata;
    integer    test_pass, test_fail;

    initial begin
        test_pass = 0;
        test_fail = 0;

        // 等待复位释放
        wait(rst_n == 1'b1);
        delay(10);
        $display("[CPU] ===== RV32EC 行为模型启动 =====");
        $display("[CPU] 时间: %0t ns", $time);

        // ─── 测试 1: 读 ROM (boot vector) ───
        $display("\n[CPU] Test 1: 读 ROM @ 0x00000000");
        read_word(32'h0000_0000, rdata);
        $display("[CPU]   ROM[0] = 0x%08h", rdata);
        if (rdata !== 32'hx && rdata !== 32'hz) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        delay(5);

        // ─── 测试 2: 写 SRAM ───
        $display("\n[CPU] Test 2: 写 SRAM @ 0x00010000");
        write_word(32'h0001_0000, 32'hCAFE_BABE);
        $display("[CPU]   写入 0xCAFE_BABE");
        delay(5);

        // ─── 测试 3: 读 SRAM 验证 ───
        $display("\n[CPU] Test 3: 读 SRAM @ 0x00010000 (验证)");
        read_word(32'h0001_0000, rdata);
        $display("[CPU]   读出 0x%08h (期望: 0xCAFE_BABE)", rdata);
        if (rdata == 32'hCAFE_BABE) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        delay(5);

        // ─── 测试 4: 写基带控制寄存器 (0x4000_0000) ───
        $display("\n[CPU] Test 4: 写基带 CTRL @ 0x40000000");
        write_word(32'h4000_0000, 32'h0000_0001);
        $display("[CPU]   写入 0x00000001 (使能基带)");
        delay(5);

        // ─── 测试 5: 读基带控制寄存器 ───
        $display("\n[CPU] Test 5: 读基带 CTRL @ 0x40000000");
        read_word(32'h4000_0000, rdata);
        $display("[CPU]   读出 0x%08h (期望: 0x00000001)", rdata);
        if (rdata == 32'h0000_0001) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        delay(5);

        // ─── 测试 6: 写 AES 密钥寄存器 ───
        $display("\n[CPU] Test 6: 写 AES KEY0 @ 0x40001008");
        write_word(32'h4000_1008, 32'h2B7E_1516);
        $display("[CPU]   写入 0x2B7E1516");
        delay(5);

        // ─── 测试 7: 读 AES 密钥寄存器 ───
        $display("\n[CPU] Test 7: 读 AES KEY0 @ 0x40001008");
        read_word(32'h4000_1008, rdata);
        $display("[CPU]   读出 0x%08h (期望: 0x2B7E1516)", rdata);
        if (rdata == 32'h2B7E_1516) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        delay(5);

        // ─── 测试 8: 写 EEPROM 控制寄存器 ───
        $display("\n[CPU] Test 8: 写 EEPROM CTRL @ 0x40002000");
        write_word(32'h4000_2000, 32'h0000_0003);
        $display("[CPU]   写入 0x00000003 (使能+写模式)");
        delay(5);

        // ─── 测试 9: 读 EEPROM 控制寄存器 ───
        $display("\n[CPU] Test 9: 读 EEPROM CTRL @ 0x40002000");
        read_word(32'h4000_2000, rdata);
        $display("[CPU]   读出 0x%08h (期望: 0x00000003)", rdata);
        if (rdata == 32'h0000_0003) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        delay(5);

        // ─── 测试 10: 地址越界 ───
        $display("\n[CPU] Test 10: 地址越界 @ 0x80000000");
        read_word(32'h8000_0000, rdata);
        $display("[CPU]   读出 0x%08h (期望: 0xDEAD_BEEF)", rdata);
        if (rdata == 32'hDEAD_BEEF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        delay(5);

        // ─── 汇总 ───
        $display("\n[CPU] ===== 自检完成 =====");
        $display("[CPU] 通过: %0d, 失败: %0d", test_pass, test_fail);
        if (test_fail == 0)
            $display("[CPU] *** 所有测试通过! ***");
        else
            $display("[CPU] *** 有 %0d 项测试失败! ***", test_fail);

        delay(20);
        $display("[CPU] CPU 挂起，等待中断...");
        // 在实际芯片中，CPU 会进入 WFI 等待中断
        // 这里仿真直接结束
        #1000;
        $display("[CPU] 仿真超时，结束");
    end

endmodule
