// ============================================================================
// 校园智能卡 SoC — 顶层模块框架
// ============================================================================
// 集成:
//   - CPU (RV32EC)
//   - AHB-Lite Bus Matrix
//   - ROM / SRAM
//   - AHB2APB Bridge
//   - 数字基带 / AES / EEPROM / PMU (在 APB 总线上)
//
// 版本: v0.1（框架，待完善）
// 负责人: 阿呆不呆
// ============================================================================

module soc_top (
    // ─── 全局时钟与复位 ───
    input  wire         clk_sys,
    input  wire         rst_n,

    // ─── 射频接口 ───
    input  wire         rf_rx,
    output wire         rf_tx,
    input  wire         rf_clk,
    input  wire         sleep,          // 射频场消失指示

    // ─── 测试接口（DFT）───
    input  wire         test_mode,
    input  wire         scan_clk,
    input  wire         scan_in,
    output wire         scan_out
);

    // ================================================================
    // 内部信号定义
    // ================================================================

    // ─── 时钟与复位 ───
    wire rst_sync_n;                    // 同步释放的复位
    wire cpu_clk, cpu_clk_gated;
    wire aes_clk, aes_clk_gated;
    wire bb_clk,  bb_clk_gated;

    // ─── CPU AHB Master 接口 ───
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

    // ─── 中断信号 ───
    wire irq_bb;                        // 数字基带中断
    wire irq_aes;                       // AES 中断
    wire irq_eep;                       // EEPROM 中断
    wire cpu_irq;                       // CPU 中断（聚合）

    // ─── APB 总线 ───
    wire        apb_clk;
    wire        apb_rst_n;
    wire        apb_psel;
    wire        apb_penable;
    wire [11:0] apb_paddr;
    wire        apb_pwrite;
    wire [31:0] apb_pwdata;
    wire [31:0] apb_prdata;
    wire        apb_pready;
    wire        apb_pslverr;

    // ================================================================
    // 例化: PMU (电源管理)
    // ================================================================
    
    pmu u_pmu (
        .clk_sys        (clk_sys),
        .rst_n          (rst_n),
        .cpu_clk_en     (1'b1),         // 暂时关闭，后续可控
        .cpu_clk_gated  (cpu_clk_gated),
        .aes_clk_en     (1'b1),
        .aes_clk_gated  (aes_clk_gated),
        .bb_clk_en      (1'b1),
        .bb_clk_gated   (bb_clk_gated),
        .rst_sync_n     (rst_sync_n),
        .sleep_en       (sleep),
        .sleep_ack      ()
    );

    // ─── 时钟分配 ───
    assign cpu_clk = clk_sys;           // 暂时同频，后续可分频
    assign aes_clk = clk_sys;
    assign bb_clk  = clk_sys;
    assign apb_clk = clk_sys;
    assign apb_rst_n = rst_sync_n;

    // ================================================================
    // 例化: CPU (RV32EC) — 行为级模型
    // ================================================================
    
    rv32ec_core u_cpu (
        .clk        (cpu_clk_gated),
        .rst_n      (rst_sync_n),
        .irq        (cpu_irq),
        .sleep_req  (),                  // 暂不连接 PMU
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
        .hresp      (cpu_hresp)
    );

    // ================================================================
    // 例化: AHB Bus Matrix (1 Master, 3 Slaves)
    // ================================================================

    wire sel_rom, sel_sram, sel_apb, sel_default;
    wire [31:0] addr_rom, addr_sram, addr_apb, addr_default;
    wire [31:0] wdata_rom, wdata_sram, wdata_apb;
    wire wr_rom, wr_sram, wr_apb, wr_default;
    wire [2:0] size_rom, size_sram, size_apb;
    wire [2:0] burst_rom, burst_sram, burst_apb;
    wire [1:0] trans_rom, trans_sram, trans_apb;
    
    wire [31:0] rd_rom, rd_sram, rd_apb;
    wire rdy_rom, rdy_sram, rdy_apb, rdy_default;
    wire [1:0] rsp_rom, rsp_sram, rsp_apb, rsp_default;

    ahb_matrix u_matrix (
        .hclk       (clk_sys),
        .hresetn    (rst_sync_n),
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

        .hsel_rom    (sel_rom),
        .haddr_rom   (addr_rom),
        .hwdata_rom  (wdata_rom),
        .hwrite_rom  (wr_rom),
        .hsize_rom   (size_rom),
        .hburst_rom  (burst_rom),
        .htrans_rom  (trans_rom),
        .hrdata_rom  (rd_rom),
        .hready_rom  (rdy_rom),
        .hresp_rom   (rsp_rom),

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

    // ================================================================
    // 默认从机响应 (地址越界: hready=1, hresp=ERROR)
    // ================================================================
    assign rdy_default = 1'b1;
    assign rsp_default = 2'b01;  // ERROR
    // ================================================================

    rom_model u_rom (
        .hclk    (clk_sys),
        .hresetn (rst_sync_n),
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

    // ================================================================
    // 例化: SRAM (8KB)
    // ================================================================

    sram_model u_sram (
        .hclk    (clk_sys),
        .hresetn (rst_sync_n),
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

    // ================================================================
    // 例化: AHB2APB Bridge
    // ================================================================

    ahb2apb_bridge u_bridge (
        .hclk    (clk_sys),
        .hresetn (rst_sync_n),
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

        .pclk    (),        // 不使用（在 Bridge 内部处理）
        .presetn (),
        .psel    (apb_psel),
        .penable (apb_penable),
        .paddr   (apb_paddr),
        .pwrite  (apb_pwrite),
        .pwdata  (apb_pwdata),
        .prdata  (apb_prdata),
        .pready  (apb_pready),
        .pslverr (apb_pslverr)
    );

    // ================================================================
    // APB 外设地址译码 (paddr[11:10] 选择 Slave)
    //   Bridge 将 AHB haddr[13:2] 映射到 paddr[11:0]:
    //     0x4000_0xxx → paddr = 0x000~0x3FF → [11:10]=00 → 基带
    //     0x4000_1xxx → paddr = 0x400~0x7FF → [11:10]=01 → AES
    //     0x4000_2xxx → paddr = 0x800~0xBFF → [11:10]=10 → EEPROM
    // ================================================================
    
    wire [31:0] apb_prdata_bb, apb_prdata_aes, apb_prdata_eep;
    wire apb_pready_bb, apb_pready_aes, apb_pready_eep;
    wire apb_pslverr_bb, apb_pslverr_aes, apb_pslverr_eep;

    wire sel_bb  = (apb_paddr[11:10] == 2'b00);
    wire sel_aes = (apb_paddr[11:10] == 2'b01);
    wire sel_eep = (apb_paddr[11:10] == 2'b10);

    // ─── APB 读数据多路选择 (纯地址译码, 不依赖 psel) ───
    assign apb_prdata = sel_bb  ? apb_prdata_bb  :
                        sel_aes ? apb_prdata_aes :
                        sel_eep ? apb_prdata_eep :
                        32'hDEAD_BEEF;

    // ─── APB 响应多路选择(同样不依赖 psel) ──
    assign apb_pready  = sel_bb  ? apb_pready_bb  :
                         sel_aes ? apb_pready_aes :
                         sel_eep ? apb_pready_eep :
                         1'b1;

    assign apb_pslverr = sel_bb  ? apb_pslverr_bb  :
                         sel_aes ? apb_pslverr_aes :
                         sel_eep ? apb_pslverr_eep :
                         1'b0;

    // ─── 外设 psel = Bridge psel AND 地址匹配 ───
    wire psel_bb  = apb_psel && sel_bb;
    wire psel_aes = apb_psel && sel_aes;
    wire psel_eep = apb_psel && sel_eep;

    // ================================================================
    // 例化: 数字基带 (Baseband) — 0x4000_0000
    // ================================================================

    bb_top u_baseband (
        .pclk    (apb_clk),
        .presetn (apb_rst_n),
        .psel    (psel_bb),
        .penable (apb_penable),
        .paddr   (apb_paddr - 12'h000),  // 基带基址 = 0x000 (word offset)
        .pwrite  (apb_pwrite),
        .pwdata  (apb_pwdata),
        .prdata  (apb_prdata_bb),
        .pready  (apb_pready_bb),
        .pslverr (apb_pslverr_bb),
        .rf_rx   (rf_rx),
        .rf_tx   (rf_tx),
        .rf_clk  (rf_clk),
        .irq_o   (irq_bb)
    );

    // ================================================================
    // 例化: AES-128 引擎 — 0x4000_1000
    // ================================================================

    aes_top u_aes (
        .pclk    (apb_clk),
        .presetn (apb_rst_n),
        .psel    (psel_aes),
        .penable (apb_penable),
        .paddr   (apb_paddr - 12'h400),  // AES 基址 = 0x400 (word offset)
        .pwrite  (apb_pwrite),
        .pwdata  (apb_pwdata),
        .prdata  (apb_prdata_aes),
        .pready  (apb_pready_aes),
        .pslverr (apb_pslverr_aes),
        .irq_o   (irq_aes)
    );

    // ================================================================
    // 例化: EEPROM 控制器 — 0x4000_2000
    // ================================================================

    eep_top u_eeprom (
        .pclk    (apb_clk),
        .presetn (apb_rst_n),
        .psel    (psel_eep),
        .penable (apb_penable),
        .paddr   (apb_paddr - 12'h800),  // EEPROM 基址 = 0x800 (word offset)
        .pwrite  (apb_pwrite),
        .pwdata  (apb_pwdata),
        .prdata  (apb_prdata_eep),
        .pready  (apb_pready_eep),
        .pslverr (apb_pslverr_eep),
        .i2c_scl (),
        .i2c_sda (),
        .irq_o   (irq_eep)
    );

    // ================================================================
    // 中断聚合 (待完善)
    // ================================================================
    
    assign cpu_irq = irq_bb | irq_aes | irq_eep;

    // ================================================================
    // 射频接口 (已连接到数字基带 bb_top)
    // ================================================================
    
    // rf_tx 由 bb_top 驱动，此处不再需要 assign

    // ================================================================
    // 测试接口占位符
    // ================================================================
    
    assign scan_out = scan_in;  // 暂时环回

endmodule
