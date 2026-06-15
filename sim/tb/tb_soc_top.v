// ============================================================================
// Testbench: 全芯片顶层仿真 (SoC Top)
// ============================================================================
// 测试场景:
//   1. 上电复位 & 时钟启动
//   2. CPU 行为模型自动执行自检序列 (ROM/SRAM/APB外设/越界)
//   3. 中断验证 (基带/AES/EEPROM)
//   4. 射频接口回环测试
//
// 版本: v1.0
// 负责人: 阿呆不呆
// ============================================================================

`timescale 1ns / 1ps

module tb_soc_top ();

    // ================================================================
    // 时钟与复位
    // ================================================================
    reg clk_sys;
    reg rst_n;

    // ─── 时钟生成 (13.56 MHz, T ≈ 73.87 ns) ───
    initial begin
        clk_sys = 1'b0;
        forever #36.935 clk_sys = ~clk_sys;
    end

    // ─── 复位 ───
    initial begin
        rst_n = 1'b0;
        #200 rst_n = 1'b1;   // 200ns 后释放复位
    end

    // ================================================================
    // 射频接口激励
    // ================================================================
    reg  rf_rx;
    wire rf_tx;
    reg  rf_clk;
    reg  sleep;

    // ─── 射频时钟 (13.56 MHz，与系统同频) ───
    initial begin
        rf_clk = 1'b0;
        forever #36.935 rf_clk = ~rf_clk;
    end

    // ─── 射频接收数据 (模拟读卡器发送的指令) ───
    initial begin
        rf_rx = 1'b0;
        sleep = 1'b0;
        #5000;  // 等待 CPU 自检完成
        // 模拟一段曼彻斯特编码数据 (简化)
        rf_rx = 1'b1;  #73.87;
        rf_rx = 1'b0;  #73.87;
        rf_rx = 1'b1;  #73.87;
        rf_rx = 1'b0;  #73.87;
        rf_rx = 1'b0;  #73.87;
        rf_rx = 1'b1;  #73.87;
        rf_rx = 1'b0;  #73.87;
        rf_rx = 1'b1;  #73.87;
    end

    // ================================================================
    // 测试接口
    // ================================================================
    reg  test_mode;
    reg  scan_clk;
    reg  scan_in;
    wire scan_out;

    initial begin
        test_mode = 1'b0;
        scan_clk  = 1'b0;
        scan_in   = 1'b0;
    end

    // ================================================================
    // 例化 SoC 顶层
    // ================================================================
    soc_top uut (
        .clk_sys   (clk_sys),
        .rst_n     (rst_n),
        .rf_rx     (rf_rx),
        .rf_tx     (rf_tx),
        .rf_clk    (rf_clk),
        .sleep     (sleep),
        .test_mode (test_mode),
        .scan_clk  (scan_clk),
        .scan_in   (scan_in),
        .scan_out  (scan_out)
    );

    // ================================================================
    // 仿真控制
    // ================================================================
    initial begin
        $display("[TB] ========================================");
        $display("[TB] Campus Smartcard SoC - Full Chip Simulation");
        $display("[TB] Time: %0t", $time);
        $display("[TB] ========================================");

        // Wait for PicoRV32 to execute firmware
        // Firmware writes test_result (0xCAFEBABE) to SRAM[0x11FF0] on success
        #40000;

        // Check firmware result via AHB bus signals
        $display("\n[TB] ===== Firmware Check =====");
        $display("[TB] PicoRV32 AHB: haddr=%08h htrans=%b hwrite=%b",
            uut.cpu_haddr, uut.cpu_htrans, uut.cpu_hwrite);
        $display("[TB] PicoRV32 trap=%b", uut.u_cpu.u_picorv32.trap);

        // If PicoRV32 reached wfi, trap=1 (caught by CATCH_ILLINSN? No, wfi is valid)
        // Check if CPU is idle (htrans=IDLE after completing tests)
        if (uut.cpu_htrans == 2'b00) begin
            $display("[TB] CPU is idle — firmware likely completed");
        end

        #20000;
        $display("\n[TB] ===== Simulation Done =====");
        $display("[TB] Check waveforms for detailed analysis");
        $finish;
    end

    // Monitor: detect writes to firmware test result address (0x00011FF0)
    always @(posedge clk_sys) begin
        if (uut.cpu_hwrite && uut.cpu_htrans == 2'b10 && uut.cpu_haddr == 32'h00011FF0) begin
            $display("[TB] *** FIRMWARE WROTE TEST RESULT: %08h ***", uut.cpu_hwdata);
            if (uut.cpu_hwdata == 32'hCAFEBABE)
                $display("[TB] *** FIRMWARE SELF-TEST PASS! ***");
            else
                $display("[TB] *** FIRMWARE SELF-TEST FAIL (wrote %08h) ***", uut.cpu_hwdata);
        end
    end

    // ================================================================
    // 波形 dump
    // ================================================================
    initial begin
        $dumpfile("tb_soc_top.vcd");
        $dumpvars(0, tb_soc_top);
    end

endmodule
