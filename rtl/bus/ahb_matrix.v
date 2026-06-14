// ============================================================================
// AHB-Lite Bus Matrix (1 Master, 3 Slaves)
// ============================================================================
// 功能: 片上总线互联，CPU 可访问 ROM/SRAM/APB Bridge
//
// 地址映射:
//   ROM      : 0x0000_0000 ~ 0x0000_3FFF (16KB)
//   SRAM     : 0x0001_0000 ~ 0x0001_1FFF (8KB)
//   APB Bridge: 0x4000_0000 ~ 0x4000_FFFF (64KB, 每外设 4KB)
//   其他     : ERROR SLAVE
//
// 版本: v1.0
// 负责人: 阿呆不呆
// ============================================================================

module ahb_matrix (
    // ─── 时钟与复位 ───
    input  wire         hclk,
    input  wire         hresetn,        // 同步释放的复位信号

    // ─── AHB Master (来自 CPU) ───
    input  wire [31:0]  haddr,
    input  wire [31:0]  hwdata,
    input  wire         hwrite,
    input  wire [2:0]   hsize,          // 传输大小
    input  wire [2:0]   hburst,         // 突发类型
    input  wire [1:0]   htrans,         // 传输类型: IDLE/BUSY/NONSEQ/SEQ
    input  wire [3:0]   hprot,          // 保护信号（本设计不用）
    input  wire         hmastlock,      // 主机锁定（本设计不用）

    output wire [31:0]  hrdata,
    output wire         hready,
    output wire [1:0]   hresp,          // OKAY=2'b00, ERROR=2'b01

    // ─── AHB Slave 0: ROM ───
    output wire         hsel_rom,
    output wire [31:0]  haddr_rom,
    output wire [31:0]  hwdata_rom,
    output wire         hwrite_rom,
    output wire [2:0]   hsize_rom,
    output wire [2:0]   hburst_rom,
    output wire [1:0]   htrans_rom,
    input  wire [31:0]  hrdata_rom,
    input  wire         hready_rom,
    input  wire [1:0]   hresp_rom,

    // ─── AHB Slave 1: SRAM ───
    output wire         hsel_sram,
    output wire [31:0]  haddr_sram,
    output wire [31:0]  hwdata_sram,
    output wire         hwrite_sram,
    output wire [2:0]   hsize_sram,
    output wire [2:0]   hburst_sram,
    output wire [1:0]   htrans_sram,
    input  wire [31:0]  hrdata_sram,
    input  wire         hready_sram,
    input  wire [1:0]   hresp_sram,

    // ─── AHB Slave 2: APB Bridge ───
    output wire         hsel_apb,
    output wire [31:0]  haddr_apb,
    output wire [31:0]  hwdata_apb,
    output wire         hwrite_apb,
    output wire [2:0]   hsize_apb,
    output wire [2:0]   hburst_apb,
    output wire [1:0]   htrans_apb,
    input  wire [31:0]  hrdata_apb,
    input  wire         hready_apb,
    input  wire [1:0]   hresp_apb,

    // ─── 默认从机（地址越界） ───
    output wire         hsel_default,
    output wire [31:0]  haddr_default,
    output wire         hwrite_default,
    input  wire         hready_default,
    input  wire [1:0]   hresp_default
);

    // ================================================================
    // 地址译码逻辑 — 组合逻辑
    // ================================================================
    
    // 根据 HADDR 的高位来判断目标从机
    wire [1:0] addr_decoder;
    
    assign addr_decoder = 
        (haddr[31:14] == 18'h00000) ? 2'b00 :    // ROM: 0x0000_0000 ~ 0x0000_3FFF
        (haddr[31:13] == 19'h00008) ? 2'b01 :    // SRAM: 0x0001_0000 ~ 0x0001_1FFF
        (haddr[31:16] == 16'h4000)  ? 2'b10 :    // APB: 0x4000_0000 ~ 0x4000_FFFF
        2'b11;                                   // 默认: ERROR SLAVE
    
    // ─── 生成各从机的选择信号 ───
    assign hsel_rom     = (addr_decoder == 2'b00) ? 1'b1 : 1'b0;
    assign hsel_sram    = (addr_decoder == 2'b01) ? 1'b1 : 1'b0;
    assign hsel_apb     = (addr_decoder == 2'b10) ? 1'b1 : 1'b0;
    assign hsel_default = (addr_decoder == 2'b11) ? 1'b1 : 1'b0;

    // ================================================================
    // 地址/控制信号多路选择 — 组合逻辑
    // ================================================================
    // 所有从机获得相同的地址、数据、控制信号
    // （这是 AHB-Lite 的特点，所有从机并联在总线上）
    
    assign haddr_rom     = haddr;
    assign hwdata_rom    = hwdata;
    assign hwrite_rom    = hwrite;
    assign hsize_rom     = hsize;
    assign hburst_rom    = hburst;
    assign htrans_rom    = htrans;

    assign haddr_sram    = haddr;
    assign hwdata_sram   = hwdata;
    assign hwrite_sram   = hwrite;
    assign hsize_sram    = hsize;
    assign hburst_sram   = hburst;
    assign htrans_sram   = htrans;

    assign haddr_apb     = haddr;
    assign hwdata_apb    = hwdata;
    assign hwrite_apb    = hwrite;
    assign hsize_apb     = hsize;
    assign hburst_apb    = hburst;
    assign htrans_apb    = htrans;

    assign haddr_default = haddr;
    assign hwrite_default= hwrite;

    // ================================================================
    // 读数据多路选择 — 组合逻辑
    // ================================================================
    
    reg [31:0]  hrdata_mux;
    reg         hready_mux;
    reg [1:0]   hresp_mux;

    always @(*) begin
        case (addr_decoder)
            2'b00: begin  // ROM
                hrdata_mux = hrdata_rom;
                hready_mux = hready_rom;
                hresp_mux  = hresp_rom;
            end
            2'b01: begin  // SRAM
                hrdata_mux = hrdata_sram;
                hready_mux = hready_sram;
                hresp_mux  = hresp_sram;
            end
            2'b10: begin  // APB Bridge
                hrdata_mux = hrdata_apb;
                hready_mux = hready_apb;
                hresp_mux  = hresp_apb;
            end
            2'b11: begin  // Default (ERROR)
                hrdata_mux = 32'hDEAD_BEEF;  // 特征值便于调试
                hready_mux = hready_default;
                hresp_mux  = hresp_default;  // ERROR (2'b01)
            end
            default: begin
                hrdata_mux = 32'hXXXX_XXXX;
                hready_mux = 1'bx;
                hresp_mux  = 2'bxx;
            end
        endcase
    end

    // ═══════════════════════════════════════════════════════════════
    // 输出驱动 — 直接连接多路选择结果
    // ═══════════════════════════════════════════════════════════════
    
    assign hrdata = hrdata_mux;
    assign hready = hready_mux;
    assign hresp  = hresp_mux;

endmodule
