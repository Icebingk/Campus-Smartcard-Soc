// ============================================================================
// Testbench: AHB-Lite Bus + AHB2APB Bridge 验证
// ============================================================================
// 测试场景:
//   1. ROM 读取
//   2. SRAM 读写
//   3. APB Bridge 读写（含外设模拟）
//   4. 地址越界处理
//
// 版本: v1.0
// 负责人: 阿呆不呆
// ============================================================================

`timescale 1ns / 1ps

module tb_ahb_bus ();

    // ================================================================
    // 时钟与复位信号（由 testbench 产生）
    // ================================================================
    
    reg clk_sys;
    reg rst_n;

    // ──── 时钟生成 (13.56 MHz 仿真频率) ────
    initial begin
        clk_sys = 1'b0;
        forever #36.935 clk_sys = ~clk_sys;  // T ≈ 73.87 ns
    end

    // ──── 复位 ────
    initial begin
        rst_n = 1'b0;
        #100 rst_n = 1'b1;  // 100ns 后释放复位
    end

    // ================================================================
    // 实例化顶层（Bus Matrix + Bridge + ROM + SRAM）
    // ================================================================

    // ─── AHB Master 信号（来自 BFM）───
    wire [31:0] cpu_haddr;
    wire [31:0] cpu_hwdata;
    wire        cpu_hwrite;
    wire [2:0]  cpu_hsize;
    wire [2:0]  cpu_hburst;
    wire [1:0]  cpu_htrans;
    wire [3:0]  cpu_hprot;
    wire        cpu_hmastlock;
    wire [31:0] cpu_hrdata;
    wire        cpu_hready;
    wire [1:0]  cpu_hresp;

    // ─── 总线矩阵输出（到各 Slave）───
    wire        sel_rom, sel_sram, sel_apb, sel_default;
    wire [31:0] addr_rom, addr_sram, addr_apb, addr_default;
    wire [31:0] wdata_rom, wdata_sram, wdata_apb;
    wire        wr_rom, wr_sram, wr_apb, wr_default;
    wire [2:0]  size_rom, size_sram, size_apb;
    wire [2:0]  burst_rom, burst_sram, burst_apb;
    wire [1:0]  trans_rom, trans_sram, trans_apb;

    // ─── Slave 响应信号 ───
    wire [31:0] rd_rom, rd_sram, rd_apb;
    wire        rdy_rom, rdy_sram, rdy_apb, rdy_default;
    wire [1:0]  rsp_rom, rsp_sram, rsp_apb, rsp_default;

    // ─── APB Bridge 的 APB 输出 ───
    wire [11:0] paddr;
    wire [31:0] pwdata;
    wire        psel;
    wire        penable;
    wire        pwrite;
    wire [31:0] prdata;
    wire        pready;
    wire        pslverr;

    // ================================================================
    // 例化模块
    // ================================================================

    ahb_master_bfm u_master (
        .hclk      (clk_sys),
        .hresetn   (rst_n),
        .haddr     (cpu_haddr),
        .hwdata    (cpu_hwdata),
        .hwrite    (cpu_hwrite),
        .hsize     (cpu_hsize),
        .hburst    (cpu_hburst),
        .htrans    (cpu_htrans),
        .hprot     (cpu_hprot),
        .hmastlock (cpu_hmastlock),
        .hrdata    (cpu_hrdata),
        .hready    (cpu_hready),
        .hresp     (cpu_hresp)
    );

    ahb_matrix u_matrix (
        .hclk       (clk_sys),
        .hresetn    (rst_n),
        .haddr      (cpu_haddr),
        .hwdata     (cpu_hwdata),
        .hwrite     (cpu_hwrite),
        .hsize      (cpu_hsize),
        .hburst     (cpu_hburst),
        .htrans     (cpu_htrans),
        .hprot      (cpu_hprot),
        .hmastlock  (cpu_hmastlock),
        .hrdata     (cpu_hrdata),
        .hready     (cpu_hready),
        .hresp      (cpu_hresp),

        .hsel_rom   (sel_rom),
        .haddr_rom  (addr_rom),
        .hwdata_rom (wdata_rom),
        .hwrite_rom (wr_rom),
        .hsize_rom  (size_rom),
        .hburst_rom (burst_rom),
        .htrans_rom (trans_rom),
        .hrdata_rom (rd_rom),
        .hready_rom (rdy_rom),
        .hresp_rom  (rsp_rom),

        .hsel_sram   (sel_sram),
        .haddr_sram  (addr_sram),
        .hwdata_sram (wdata_sram),
        .hwrite_sram (wr_sram),
        .hsize_sram  (size_sram),
        .hburst_sram (burst_sram),
        .htrans_sram (trans_sram),
        .hrdata_sram (rd_sram),
        .hready_sram (rdy_sram),
        .hresp_sram  (rsp_sram),

        .hsel_apb    (sel_apb),
        .haddr_apb   (addr_apb),
        .hwdata_apb  (wdata_apb),
        .hwrite_apb  (wr_apb),
        .hsize_apb   (size_apb),
        .hburst_apb  (burst_apb),
        .htrans_apb  (trans_apb),
        .hrdata_apb  (rd_apb),
        .hready_apb  (rdy_apb),
        .hresp_apb   (rsp_apb),

        .hsel_default   (sel_default),
        .haddr_default  (addr_default),
        .hwrite_default (wr_default),
        .hready_default (rdy_default),
        .hresp_default  (rsp_default)
    );

    rom_model u_rom (
        .hclk    (clk_sys),
        .hresetn (rst_n),
        .hsel    (sel_rom),
        .haddr   (addr_rom),
        .hwdata  (wdata_rom),
        .hwrite  (wr_rom),
        .hsize   (size_rom),
        .hburst  (burst_rom),
        .htrans  (trans_rom),
        .hrdata  (rd_rom),
        .hready  (rdy_rom),
        .hresp   (rsp_rom)
    );

    sram_model u_sram (
        .hclk    (clk_sys),
        .hresetn (rst_n),
        .hsel    (sel_sram),
        .haddr   (addr_sram),
        .hwdata  (wdata_sram),
        .hwrite  (wr_sram),
        .hsize   (size_sram),
        .hburst  (burst_sram),
        .htrans  (trans_sram),
        .hrdata  (rd_sram),
        .hready  (rdy_sram),
        .hresp   (rsp_sram)
    );

    ahb2apb_bridge u_bridge (
        .hclk    (clk_sys),
        .hresetn (rst_n),
        .hsel    (sel_apb),
        .haddr   (addr_apb),
        .hwdata  (wdata_apb),
        .hwrite  (wr_apb),
        .hsize   (size_apb),
        .hburst  (burst_apb),
        .htrans  (trans_apb),
        .hrdata  (rd_apb),
        .hready  (rdy_apb),
        .hresp   (rsp_apb),

        .pclk    (),        // 不使用
        .presetn (),        // 不使用
        .psel    (psel),
        .penable (penable),
        .paddr   (paddr),
        .pwrite  (pwrite),
        .pwdata  (pwdata),
        .prdata  (prdata),
        .pready  (pready),
        .pslverr (pslverr)
    );

    // ─── APB 从机模拟 (简单回读) ───
    assign prdata  = pwdata;      // Echo 写入数据作为读结果
    assign pready  = 1'b1;        // 无等待
    assign pslverr = 1'b0;        // 无错误

    // ================================================================
    // 仿真场景 (Stimulus)
    // ================================================================

    reg [31:0] read_data;
    integer    i;

    initial begin
        $display("[TB] 启动仿真...");
        $display("时间: %0t", $time);

        // ──── 等待复位释放 ────
        wait(rst_n == 1'b1);
        u_master.delay_cycles(5);
        $display("[TB] 复位释放完成");

        // ──── 场景 1: 读 ROM ────
        $display("\n[TB] ===== 场景 1: 读 ROM =====");
        u_master.read_word(32'h0000_0000, read_data);
        $display("[TB] 从 0x00000000 读取: 0x%08x", read_data);

        u_master.delay_cycles(2);

        // ──── 场景 2: 写 SRAM ────
        $display("\n[TB] ===== 场景 2: 写 SRAM =====");
        u_master.write_word(32'h0001_0000, 32'hDEAD_BEEF);
        $display("[TB] 向 0x00010000 写入: 0xDEAD_BEEF");

        u_master.delay_cycles(2);

        // ──── 场景 3: 读 SRAM (验证写入) ────
        $display("\n[TB] ===== 场景 3: 读 SRAM (验证写入) =====");
        u_master.read_word(32'h0001_0000, read_data);
        $display("[TB] 从 0x00010000 读取: 0x%08x (期望: 0xDEAD_BEEF)", read_data);

        u_master.delay_cycles(2);

        // ──── 场景 4: 写 APB 外设 ────
        $display("\n[TB] ===== 场景 4: 写 APB 外设 (基带控制寄存器) =====");
        u_master.write_word(32'h4000_0000, 32'h0000_0001);
        $display("[TB] 向 0x40000000 写入: 0x00000001 (基带控制寄存器)");

        u_master.delay_cycles(2);

        // ──── 场景 5: 读 APB 外设 ────
        $display("\n[TB] ===== 场景 5: 读 APB 外设 (基带控制寄存器) =====");
        u_master.read_word(32'h4000_0000, read_data);
        $display("[TB] 从 0x40000000 读取: 0x%08x (期望: 0x00000001)", read_data);

        u_master.delay_cycles(2);

        // ──── 场景 6: 读 AES 外设 ────
        $display("\n[TB] ===== 场景 6: 读 AES 外设 (密钥寄存器) =====");
        u_master.read_word(32'h4000_1008, read_data);
        $display("[TB] 从 0x40001008 读取: 0x%08x", read_data);

        u_master.delay_cycles(2);

        // ──── 场景 7: 地址越界 ────
        $display("\n[TB] ===== 场景 7: 地址越界 (ERROR Slave) =====");
        u_master.read_word(32'h8000_0000, read_data);
        $display("[TB] 从 0x80000000 读取: 0x%08x (期望: 0xDEAD_BEEF)", read_data);

        u_master.delay_cycles(5);

        $display("\n[TB] ===== 仿真完成 =====");
        $finish;
    end

    // ================================================================
    // 波形生成 (VCD dump) — ModelSim 会自动处理
    // ================================================================
    
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_ahb_bus);
    end

endmodule
