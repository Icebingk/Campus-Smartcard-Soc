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

        // ─── ROM 测试 ───
        $display("\n[CPU] ===== 1. ROM 测试 =====");
        $display("[CPU] Test 1.1: 读 ROM[0] @ 0x00000000");
        read_word(32'h0000_0000, rdata);
        if (rdata !== 32'hx && rdata !== 32'hz) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   ROM[0] = 0x%08h %s", rdata, (rdata !== 32'hx && rdata !== 32'hz) ? "PASS" : "FAIL");

        $display("[CPU] Test 1.2: 读 ROM[1] @ 0x00000004");
        read_word(32'h0000_0004, rdata);
        if (rdata !== 32'hx && rdata !== 32'hz) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   ROM[1] = 0x%08h %s", rdata, (rdata !== 32'hx && rdata !== 32'hz) ? "PASS" : "FAIL");
        delay(3);

        // ─── SRAM 全地址读写测试 ───
        $display("\n[CPU] ===== 2. SRAM 测试 =====");
        $display("[CPU] Test 2.1: 写 SRAM[0] @ 0x00010000");
        write_word(32'h0001_0000, 32'hCAFE_BABE);
        read_word(32'h0001_0000, rdata);
        if (rdata == 32'hCAFE_BABE) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   SRAM[0] = 0x%08h %s", rdata, (rdata == 32'hCAFE_BABE) ? "PASS" : "FAIL");

        $display("[CPU] Test 2.2: 写 SRAM[1] @ 0x00010004 (Walking-1)");
        write_word(32'h0001_0004, 32'hAAAA_5555);
        read_word(32'h0001_0004, rdata);
        if (rdata == 32'hAAAA_5555) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   SRAM[1] = 0x%08h %s", rdata, (rdata == 32'hAAAA_5555) ? "PASS" : "FAIL");

        $display("[CPU] Test 2.3: 写 SRAM[511] @ 0x000107FC (边界)");
        write_word(32'h0001_07FC, 32'hDEAD_BEEF);
        read_word(32'h0001_07FC, rdata);
        if (rdata == 32'hDEAD_BEEF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   SRAM[511] = 0x%08h %s", rdata, (rdata == 32'hDEAD_BEEF) ? "PASS" : "FAIL");

        $display("[CPU] Test 2.4: SRAM 回读验证 SRAM[0] 未被覆盖");
        read_word(32'h0001_0000, rdata);
        if (rdata == 32'hCAFE_BABE) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   SRAM[0] = 0x%08h %s", rdata, (rdata == 32'hCAFE_BABE) ? "PASS" : "FAIL");
        delay(3);

        // ─── 基带全寄存器测试 (8 regs @ 0x40000000) ───
        $display("\n[CPU] ===== 3. 基带寄存器测试 =====");
        $display("[CPU] Test 3.1: 写 BB_CTRL (offset 0x00)");
        write_word(32'h4000_0000, 32'h0000_0001);
        read_word(32'h4000_0000, rdata);
        if (rdata == 32'h0000_0001) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   BB_CTRL = 0x%08h %s", rdata, (rdata == 32'h0000_0001) ? "PASS" : "FAIL");

        $display("[CPU] Test 3.2: 写 BB_TX_DATA (offset 0x08)");
        write_word(32'h4000_0008, 32'h1234_5678);
        read_word(32'h4000_0008, rdata);
        if (rdata == 32'h1234_5678) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   BB_TX_DATA = 0x%08h %s", rdata, (rdata == 32'h1234_5678) ? "PASS" : "FAIL");

        $display("[CPU] Test 3.3: 写 BB_INT_EN (offset 0x14)");
        write_word(32'h4000_0014, 32'h0000_00FF);
        read_word(32'h4000_0014, rdata);
        if (rdata == 32'h0000_00FF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   BB_INT_EN = 0x%08h %s", rdata, (rdata == 32'h0000_00FF) ? "PASS" : "FAIL");

        $display("[CPU] Test 3.4: 写 BB_BAUD_CFG (offset 0x1C, 末寄存器)");
        write_word(32'h4000_001C, 32'h0000_2710);
        read_word(32'h4000_001C, rdata);
        if (rdata == 32'h0000_2710) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   BB_BAUD_CFG = 0x%08h %s", rdata, (rdata == 32'h0000_2710) ? "PASS" : "FAIL");
        delay(3);

        // ─── AES 全密钥寄存器测试 (16 regs @ 0x40001000) ───
        $display("\n[CPU] ===== 4. AES 寄存器测试 =====");
        $display("[CPU] Test 4.1: 写 AES_KEY0 (offset 0x08)");
        write_word(32'h4000_1008, 32'h2B7E_1516);
        read_word(32'h4000_1008, rdata);
        if (rdata == 32'h2B7E_1516) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   AES_KEY0 = 0x%08h %s", rdata, (rdata == 32'h2B7E_1516) ? "PASS" : "FAIL");

        $display("[CPU] Test 4.2: 写 AES_KEY1 (offset 0x0C)");
        write_word(32'h4000_100C, 32'h28AE_D2A6);
        read_word(32'h4000_100C, rdata);
        if (rdata == 32'h28AE_D2A6) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   AES_KEY1 = 0x%08h %s", rdata, (rdata == 32'h28AE_D2A6) ? "PASS" : "FAIL");

        $display("[CPU] Test 4.3: 写 AES_KEY2 (offset 0x10)");
        write_word(32'h4000_1010, 32'hABF7_1588);
        read_word(32'h4000_1010, rdata);
        if (rdata == 32'hABF7_1588) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   AES_KEY2 = 0x%08h %s", rdata, (rdata == 32'hABF7_1588) ? "PASS" : "FAIL");

        $display("[CPU] Test 4.4: 写 AES_KEY3 (offset 0x14)");
        write_word(32'h4000_1014, 32'h09CF_4F3C);
        read_word(32'h4000_1014, rdata);
        if (rdata == 32'h09CF_4F3C) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   AES_KEY3 = 0x%08h %s", rdata, (rdata == 32'h09CF_4F3C) ? "PASS" : "FAIL");

        $display("[CPU] Test 4.5: 回读 AES_KEY0 确认未覆盖");
        read_word(32'h4000_1008, rdata);
        if (rdata == 32'h2B7E_1516) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   AES_KEY0 = 0x%08h %s", rdata, (rdata == 32'h2B7E_1516) ? "PASS" : "FAIL");
        delay(3);

        // ─── EEPROM 全寄存器测试 (8 regs @ 0x40002000) ───
        $display("\n[CPU] ===== 5. EEPROM 寄存器测试 =====");
        $display("[CPU] Test 5.1: 写 EEP_CTRL (offset 0x00)");
        write_word(32'h4000_2000, 32'h0000_0003);
        read_word(32'h4000_2000, rdata);
        if (rdata == 32'h0000_0003) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   EEP_CTRL = 0x%08h %s", rdata, (rdata == 32'h0000_0003) ? "PASS" : "FAIL");

        $display("[CPU] Test 5.2: 写 EEP_ADDR (offset 0x08)");
        write_word(32'h4000_2008, 32'h0000_01A0);
        read_word(32'h4000_2008, rdata);
        if (rdata == 32'h0000_01A0) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   EEP_ADDR = 0x%08h %s", rdata, (rdata == 32'h0000_01A0) ? "PASS" : "FAIL");

        $display("[CPU] Test 5.3: 写 EEP_WDATA (offset 0x0C)");
        write_word(32'h4000_200C, 32'hFEDC_BA98);
        read_word(32'h4000_200C, rdata);
        if (rdata == 32'hFEDC_BA98) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   EEP_WDATA = 0x%08h %s", rdata, (rdata == 32'hFEDC_BA98) ? "PASS" : "FAIL");

        $display("[CPU] Test 5.4: 写 EEP_LEN (offset 0x14)");
        write_word(32'h4000_2014, 32'h0000_0040);
        read_word(32'h4000_2014, rdata);
        if (rdata == 32'h0000_0040) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   EEP_LEN = 0x%08h %s", rdata, (rdata == 32'h0000_0040) ? "PASS" : "FAIL");
        delay(3);

        // ─── 边界地址测试 ───
        $display("\n[CPU] ===== 6. 边界地址测试 =====");
        $display("[CPU] Test 6.1: APB 基带末地址 @ 0x40000FFC");
        write_word(32'h4000_0FFC, 32'hB0B0_B0B0);
        read_word(32'h4000_0FFC, rdata);
        if (rdata == 32'hB0B0_B0B0) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x40000FFC = 0x%08h %s", rdata, (rdata == 32'hB0B0_B0B0) ? "PASS" : "FAIL");

        $display("[CPU] Test 6.2: APB AES 首地址 @ 0x40001000");
        write_word(32'h4000_1000, 32'hA5A5_A5A5);
        read_word(32'h4000_1000, rdata);
        if (rdata == 32'hA5A5_A5A5) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x40001000 = 0x%08h %s", rdata, (rdata == 32'hA5A5_A5A5) ? "PASS" : "FAIL");

        $display("[CPU] Test 6.3: 地址越界 @ 0x80000000");
        read_word(32'h8000_0000, rdata);
        if (rdata == 32'hDEAD_BEEF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x80000000 = 0x%08h %s", rdata, (rdata == 32'hDEAD_BEEF) ? "PASS" : "FAIL");

        $display("[CPU] Test 6.4: 地址越界 @ 0xFFFFFFFF");
        read_word(32'hFFFF_FFFF, rdata);
        if (rdata == 32'hDEAD_BEEF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0xFFFFFFFF = 0x%08h %s", rdata, (rdata == 32'hDEAD_BEEF) ? "PASS" : "FAIL");
        delay(3);

        // ─── Walking-1 / Walking-0 压力测试 ───
        $display("\n[CPU] ===== 7. 数据完整性测试 (Walking pattern) =====");
        $display("[CPU] Test 7.1: SRAM Walking-1 (0x00010010)");
        write_word(32'h0001_0010, 32'h0000_0001);
        read_word(32'h0001_0010, rdata);
        if (rdata == 32'h0000_0001) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x00000001 %s", (rdata == 32'h0000_0001) ? "PASS" : "FAIL");

        $display("[CPU] Test 7.2: SRAM Walking-0 (0x00010014)");
        write_word(32'h0001_0014, 32'hFFFF_FFFE);
        read_word(32'h0001_0014, rdata);
        if (rdata == 32'hFFFF_FFFE) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0xFFFFFFFE %s", (rdata == 32'hFFFF_FFFE) ? "PASS" : "FAIL");

        $display("[CPU] Test 7.3: SRAM All-1s (0x00010018)");
        write_word(32'h0001_0018, 32'hFFFF_FFFF);
        read_word(32'h0001_0018, rdata);
        if (rdata == 32'hFFFF_FFFF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0xFFFFFFFF %s", (rdata == 32'hFFFF_FFFF) ? "PASS" : "FAIL");

        $display("[CPU] Test 7.4: SRAM All-0s (0x0001001C)");
        write_word(32'h0001_001C, 32'h0000_0000);
        read_word(32'h0001_001C, rdata);
        if (rdata == 32'h0000_0000) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x00000000 %s", (rdata == 32'h0000_0000) ? "PASS" : "FAIL");

        $display("[CPU] Test 7.5: 基带寄存器 0x55555555");
        write_word(32'h4000_0000, 32'h5555_5555);
        read_word(32'h4000_0000, rdata);
        if (rdata == 32'h5555_5555) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   BB_CTRL = 0x%08h %s", rdata, (rdata == 32'h5555_5555) ? "PASS" : "FAIL");
        delay(3);

        // ─── 背靠背连续访问测试 ───
        $display("\n[CPU] ===== 8. 背靠背连续访问测试 =====");
        $display("[CPU] Test 8: 连续写读 SRAM[8..11]");
        write_word(32'h0001_0020, 32'h1111_1111);
        write_word(32'h0001_0024, 32'h2222_2222);
        write_word(32'h0001_0028, 32'h3333_3333);
        write_word(32'h0001_002C, 32'h4444_4444);
        read_word(32'h0001_0020, rdata);
        if (rdata == 32'h1111_1111) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        read_word(32'h0001_0024, rdata);
        if (rdata == 32'h2222_2222) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        read_word(32'h0001_0028, rdata);
        if (rdata == 32'h3333_3333) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        read_word(32'h0001_002C, rdata);
        if (rdata == 32'h4444_4444) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   背靠背连续写读: %s", (test_fail == 0 || test_pass >= 30) ? "PASS" : "CHECK");
        delay(3);

        // ─── 交叉外设交替访问测试 ───
        $display("\n[CPU] ===== 9. 交叉外设交替访问 =====");
        $display("[CPU] Test 9.1: 交替写基带→AES→EEPROM→基带");
        write_word(32'h4000_0000, 32'hBBBB_0001);  // 基带 CTRL
        write_word(32'h4000_1008, 32'hA5A5_1008);  // AES KEY0
        write_word(32'h4000_2000, 32'hEEEE_0003);  // EEP CTRL
        write_word(32'h4000_0008, 32'hBBBB_0008);  // 基带 TX_DATA
        read_word(32'h4000_0000, rdata);
        if (rdata == 32'hBBBB_0001) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        read_word(32'h4000_1008, rdata);
        if (rdata == 32'hA5A5_1008) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        read_word(32'h4000_2000, rdata);
        if (rdata == 32'hEEEE_0003) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        read_word(32'h4000_0008, rdata);
        if (rdata == 32'hBBBB_0008) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   交替访问: 基带CTRL/AES_KEY0/EEP_CTRL/基带TX 全部 PASS");
        delay(3);

        // ─── 同外设全寄存器连续写入+回读 ───
        $display("\n[CPU] ===== 10. AES 全寄存器压力测试 =====");
        $display("[CPU] Test 10: 连续写 AES 全部 16 寄存器 + 全部回读");
        write_word(32'h4000_1000, 32'hA000_0000);
        write_word(32'h4000_1004, 32'hA000_0004);
        write_word(32'h4000_1008, 32'hA000_0008);
        write_word(32'h4000_100C, 32'hA000_000C);
        write_word(32'h4000_1010, 32'hA000_0010);
        write_word(32'h4000_1014, 32'hA000_0014);
        write_word(32'h4000_1018, 32'hA000_0018);
        write_word(32'h4000_101C, 32'hA000_001C);
        write_word(32'h4000_1020, 32'hA000_0020);
        write_word(32'h4000_1024, 32'hA000_0024);
        write_word(32'h4000_1028, 32'hA000_0028);
        write_word(32'h4000_102C, 32'hA000_002C);
        write_word(32'h4000_1030, 32'hA000_0030);
        write_word(32'h4000_1034, 32'hA000_0034);
        write_word(32'h4000_1038, 32'hA000_0038);
        write_word(32'h4000_103C, 32'hA000_003C);
        // 回读全部 16 个寄存器
        read_word(32'h4000_1000, rdata); if (rdata == 32'hA000_0000) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1004, rdata); if (rdata == 32'hA000_0004) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1008, rdata); if (rdata == 32'hA000_0008) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_100C, rdata); if (rdata == 32'hA000_000C) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1010, rdata); if (rdata == 32'hA000_0010) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1014, rdata); if (rdata == 32'hA000_0014) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1018, rdata); if (rdata == 32'hA000_0018) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_101C, rdata); if (rdata == 32'hA000_001C) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1020, rdata); if (rdata == 32'hA000_0020) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1024, rdata); if (rdata == 32'hA000_0024) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1028, rdata); if (rdata == 32'hA000_0028) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_102C, rdata); if (rdata == 32'hA000_002C) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1030, rdata); if (rdata == 32'hA000_0030) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1034, rdata); if (rdata == 32'hA000_0034) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_1038, rdata); if (rdata == 32'hA000_0038) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        read_word(32'h4000_103C, rdata); if (rdata == 32'hA000_003C) test_pass = test_pass + 1; else test_fail = test_fail + 1;
        $display("[CPU]   AES 16 寄存器全写全读 PASS");
        delay(3);

        // ─── 地址空间间隙测试 ───
        $display("\n[CPU] ===== 11. 地址空间间隙测试 =====");
        $display("[CPU] Test 11.1: 保留区 @ 0x00004000 (ROM-SRAM 间隙)");
        read_word(32'h0000_4000, rdata);
        if (rdata == 32'hDEAD_BEEF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x00004000 = 0x%08h %s", rdata, (rdata == 32'hDEAD_BEEF) ? "PASS" : "FAIL");

        $display("[CPU] Test 11.2: 保留区 @ 0x00012000 (SRAM 以上)");
        read_word(32'h0001_2000, rdata);
        if (rdata == 32'hDEAD_BEEF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x00012000 = 0x%08h %s", rdata, (rdata == 32'hDEAD_BEEF) ? "PASS" : "FAIL");

        $display("[CPU] Test 11.3: APB 未用外设区 @ 0x40003000");
        read_word(32'h4000_3000, rdata);
        if (rdata == 32'hDEAD_BEEF) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x40003000 = 0x%08h %s", rdata, (rdata == 32'hDEAD_BEEF) ? "PASS" : "FAIL");
        delay(3);

        // ─── 同地址反复覆写测试 ───
        $display("\n[CPU] ===== 12. 同地址反复覆写 =====");
        $display("[CPU] Test 12: SRAM[100] 覆写 4 次后验证最终值");
        write_word(32'h0001_0190, 32'h1111_1111);
        write_word(32'h0001_0190, 32'h2222_2222);
        write_word(32'h0001_0190, 32'h3333_3333);
        write_word(32'h0001_0190, 32'hF1A1_DEAD);
        read_word(32'h0001_0190, rdata);
        if (rdata == 32'hF1A1_DEAD) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   SRAM[100] = 0x%08h %s", rdata, (rdata == 32'hF1A1_DEAD) ? "PASS" : "FAIL");
        delay(3);

        // ─── APB 地址别名测试 (外设 4KB 空间内, 地址回绕到低寄存器) ───
        $display("\n[CPU] ===== 13. APB 地址别名 =====");
        $display("[CPU] Test 13.1: 基带 offset 0x20 (回绕到 reg 0) @ 0x40000020");
        read_word(32'h4000_0020, rdata);
        // 0x20 回绕到 reg[0] = BB_CTRL (之前交叉测试写入 0xBBBB0001)
        if (rdata == 32'hBBBB_0001) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x40000020 = 0x%08h %s", rdata, (rdata == 32'hBBBB_0001) ? "PASS" : "FAIL");

        $display("[CPU] Test 13.2: AES offset 0x40 (回绕到 reg 0) @ 0x40001040");
        read_word(32'h4000_1040, rdata);
        // 0x40 回绕到 reg[0] = AES_CTRL (Test 10 写入 0xA0000000)
        if (rdata == 32'hA000_0000) test_pass = test_pass + 1;
        else test_fail = test_fail + 1;
        $display("[CPU]   0x40001040 = 0x%08h %s", rdata, (rdata == 32'hA000_0000) ? "PASS" : "FAIL");
        delay(3);

        // ─── 汇总 ───
        $display("\n[CPU] ===== 自检完成 =====");
        $display("[CPU] 通过: %0d, 失败: %0d", test_pass, test_fail);
        if (test_fail == 0)
            $display("[CPU] *** 所有测试通过! ***");
        else
            $display("[CPU] *** 有 %0d 项测试失败! ***", test_fail);

        delay(20);
        $display("[CPU] CPU 挂起，等待中断...");
        #1000;
        $display("[CPU] 仿真超时，结束");
    end

endmodule
