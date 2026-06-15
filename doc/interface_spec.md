# 校园智能卡 SoC — 模块接口信号规范

> **版本**: v1.1  
> **日期**: 2026-06-15  
> **负责人**: 阿呆不呆  
> **适用对象**: 林子轩（数字基带）、梁芷晴（AES-128）、所有挂载 APB 总线的模块
> **CPU 更新**: 已集成开源 PicoRV32 (RV32EC)，仿真用 BFM、综合用 PicoRV32 wrapper

---

## 1. 全芯片顶层接口

```
                    ┌──────────────────────────┐
     clk_sys ──────▶│                          │
     rst_n    ──────▶│      soc_top             │
                    │                          │
     rf_rx    ──────▶│   ┌─────┐  ┌──────────┐ │──────▶ rf_tx
                    │   │CPU  │  │Digital    │ │
     rf_clk   ──────▶│   │RISC-│  │Baseband  │ │
                    │   │V    │  │(FSM)     │ │
     sleep    ──────▶│   └──┬──┘  └────┬─────┘ │
                    │      │          │        │
                    │   ┌──┴──────────┴──┐     │
                    │   │  AMBA Bus      │     │
                    │   │  AHB+APB       │     │
                    │   └───────────────┘     │
                    └──────────────────────────┘
```

### 1.1 顶层端口列表

| 端口名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| `clk_sys` | input | 1 | 系统主时钟（射频场恢复，预计 13.56MHz 或分频） |
| `rst_n` | input | 1 | 系统异步复位（低有效） |
| `rf_rx` | input | 1 | 射频接收数据（经 AFE 解调后的数字信号） |
| `rf_tx` | output | 1 | 射频发送数据（待调制） |
| `sleep` | input | 1 | 休眠信号（射频场消失指示） |
| `test_mode` | input | 1 | 测试模式使能（扫描链/DFT） |
| `scan_clk` | input | 1 | 测试时钟 |
| `scan_in` | input | 1 | 测试输入 |
| `scan_out` | output | 1 | 测试输出 |

---

## 2. APB 从机接口（所有外设模块必须遵守）

> 参照 AMBA APB4 协议简化版，**每个挂载到 APB 总线的模块必须实现以下端口**。

### 2.1 标准 APB 从机端口

```verilog
module your_module_apb (
    // ─── APB Slave Interface (必选) ───
    input  wire        pclk,        // APB 时钟
    input  wire        presetn,     // APB 复位（低有效，同步释放）
    input  wire        psel,        // 从机选择（地址译码后）
    input  wire        penable,     // APB 使能（第二周期）
    input  wire [11:0] paddr,       // 地址（12-bit，寻址 4KB）
    input  wire        pwrite,      // 1=写, 0=读
    input  wire [31:0] pwdata,      // 写数据
    output wire [31:0] prdata,      // 读数据
    output wire        pready,      // 就绪（可插入等待，常接 1）
    output wire        pslverr,     // 传输错误（常接 0）
    
    // ─── 中断输出（连接到 CPU 中断控制器）───
    output wire        irq_o         // 中断请求（高有效）
);
```

### 2.2 APB 时序要求

```
         T0      T1      T2      T3      T4
         ──┐     ──┐     ──┐     ──┐     ──┐
pclk   ──┘   ────┘   ────┘   ────┘   ────┘

psel   ────────────────┐               ┌──────
                       └───────────────┘
penable─────────────────┐             ┌──────
                        └─────────────┘
pwrite ────────────────┐               ┌──────
                       └───────────────┘
paddr  ────< ADDR >────┐               ┌──────
                       └───────────────┘
pwdata ────< WDATA >───┐               ┌──────
                       └───────────────┘
prdata ────────────────┐   < RDATA >   ┌──────
                       └───────────────┘
pready ────────────────┐               ┌──────
                       └───────────────┘
```

- **Setup 周期 (T1→T2)**：`psel=1`, `penable=0`，地址和数据有效
- **Access 周期 (T2→T3)**：`psel=1`, `penable=1`，从机在此时采样/输出
- **pready**：正常为 `1`，拉低可插入等待周期
- **pslverr**：正常为 `0`，拉高指示非法的寄存器访问

---

## 3. AHB-Lite 总线内部接口

> 内部互联使用，由阿呆不呆负责。各模块开发者**无需关心 AHB 细节**，只需实现 APB 接口即可。

### 3.1 AHB-Lite Master 接口（CPU → Bus Matrix）

> CPU 侧为 PicoRV32 内核 + AHB-Lite 适配 wrapper (`rtl/cpu/rv32ec_core.v`)。
> PicoRV32 原生内存接口 (mem_valid/addr/wdata/wstrb/ready/rdata) 经 wrapper 转换为标准 AHB-Lite 总线。

```verilog
// CPU → AHB Bus Matrix
output wire [31:0]  haddr;       // 地址 (PicoRV32: mem_addr)
output wire [31:0]  hwdata;      // 写数据 (PicoRV32: mem_wdata)
output wire         hwrite;      // 读写控制 (PicoRV32: |mem_wstrb)
output wire [2:0]   hsize;       // 传输大小 (固定 3'b010 = 32-bit)
output wire [2:0]   hburst;      // 突发类型 (固定 3'b000 = SINGLE)
output wire [1:0]   htrans;      // 传输类型 (IDLE/NONSEQ)
output wire [3:0]   hprot;       // 保护类型 (固定 4'b0011 = Data)
output wire         hmastlock;   // 锁定 (固定 0)
output wire         sleep_req;   // 休眠请求 (PicoRV32 暂未用)
input  wire [31:0]  hrdata;      // 读数据 → PicoRV32: mem_rdata
input  wire         hready;      // 就绪 → PicoRV32: mem_ready
input  wire [1:0]   hresp;       // 响应 (OKAY/ERROR)
input  wire         irq;         // 外部中断 → PicoRV32 IRQ 0
```

### 3.1.1 PicoRV32 配置参数 (RV32EC)

| 参数 | 值 | 说明 |
|------|-----|------|
| `ENABLE_REGS_16_31` | 0 | RV32E: 16 个寄存器 |
| `COMPRESSED_ISA` | 1 | C 扩展: 压缩指令 |
| `ENABLE_MUL` / `ENABLE_DIV` | 0 | 无硬件乘除 |
| `ENABLE_IRQ` | 1 | 中断支持 |
| `ENABLE_COUNTERS` | 0 | 无性能计数器 |
| `PROGADDR_RESET` | `0x00000000` | 复位向量 (ROM) |
| `PROGADDR_IRQ` | `0x00000010` | 中断向量 |
| `STACKADDR` | `0x00011FFC` | 栈指针初始值 |

### 3.2 AHB-Lite Slave 接口（ROM/SRAM/Bridge 侧）

```verilog
// AHB Bus Matrix → Slave
input  wire [31:0]  haddr;
input  wire [31:0]  hwdata;
input  wire         hwrite;
input  wire [2:0]   hsize;
input  wire [2:0]   hburst;
input  wire [1:0]   htrans;
input  wire         hsel;        // 本从机选中
output wire [31:0]  hrdata;
output wire         hready;
output wire         hresp;
```

---

## 4. 中断聚合方案

### 4.1 中断编号分配

| IRQ 编号 | 源 | 触发条件 | 处理优先级 |
|----------|-----|----------|-----------|
| 0 | 数字基带 | 防冲突完成 / 数据帧就绪 | **最高** |
| 1 | AES-128 | 加密/解密运算完成 | 高 |
| 2 | EEPROM | 读/写操作完成 | 中 |
| 3 | 保留 | — | — |

### 4.2 中断聚合电路（在 soc_top 中实现）

```verilog
// 简化中断聚合：直接线或到 CPU 中断输入
wire [3:0] irq_sources;
assign irq_sources = {1'b0, eep_irq, aes_irq, bb_irq};  
// CPU 通过查询各模块 INT_STATUS 寄存器确定中断源
```

---

## 5. EEPROM 外部接口 (I2C)

EEPROM 控制器需引出 I2C 物理层信号：

```verilog
// EEPROM 控制器顶层额外端口
output wire         i2c_scl,       // I2C 时钟 (开漏, 外部上拉)
inout  wire         i2c_sda,       // I2C 数据 (开漏, 外部上拉)
```

### I2C 时序要求
- 标准模式: 100 kHz
- 快速模式: 400 kHz
- 通过 `EEP_DIV` 寄存器配置分频系数

---

## 6. APB 写时序建议

> ⚠️ 由于 AHB2APB Bridge 的 `psel`/`penable` 为寄存器输出，建议外设在 **negedge pclk** 采样写入，确保信号已稳定。

```verilog
// 推荐写法
always @(negedge pclk or negedge presetn) begin
    if (!presetn) ...
    else if (psel && penable && pwrite && addr_ok)
        regfile[addr] <= pwdata;
end
```

---

## 7. 时钟与复位规范

### 7.1 时钟域

| 时钟名 | 频率 | 驱动域 | 说明 |
|--------|------|--------|------|
| `clk_sys` | 13.56 MHz | CPU (PicoRV32) + Bus + AES + EEPROM + PMU | 系统主时钟，射频场恢复或分频 |
| `clk_bb` | 13.56 MHz / 可配 | 数字基带 | 基带专用时钟（可能与 clk_sys 同源） |
| `rf_clk` | 13.56 MHz | AFE 接口 | 射频前端输入时钟 |

### 7.2 复位策略

```
                         ┌─────────────────┐
rst_n (async) ──────────▶│  同步释放电路    │──────▶ rst_sync_n (同步后)
                         │  (2-DFF sync)   │
                         └─────────────────┘
```

- **复位类型**：异步复位，同步释放
- **复位极性**：低有效 (`rst_n`)
- **同步器**：两级 DFF，消除亚稳态
- **复位树**：从 `soc_top` → 各子模块的 `presetn`
- **PicoRV32 复位**：`resetn = rst_sync_n`
- **仿真验证**：58 项测试全部通过

### 7.3 时钟门控策略

```verilog
// ICG (Integrated Clock Gating) 实例化示例
// 非交易态时门控 CPU 和 AES 时钟
assign clk_cpu_gated = clk_sys & cpu_clk_en;
assign clk_aes_gated = clk_sys & aes_clk_en;
```

---

## 8. 团队协作接口约定

### 8.1 模块交付标准

1. ✅ 模块顶层端口**必须**完全匹配本文档第 2.1 节 APB 从机端口列表
2. ✅ 寄存器地址偏移**必须**与 `memory_map.md` 第 3 节一致
3. ✅ 所有寄存器**必须**支持 32-bit 字对齐访问
4. ✅ `pready` 至少支持 0~3 个等待周期的可配置延迟
5. ✅ 模块内不能有 `pclk` 和 `clk_sys` 之外的独立时钟生成

### 8.2 版本管理

| 模块 | Git 分支 | RTL 文件名规范 |
|------|----------|---------------|
| 数字基带 | `baseband/dev` | `bb_top.v`, `bb_regfile.v`, `bb_fsm_*.v` |
| AES-128 | `aes/dev` | `aes_top.v`, `aes_core.v`, `aes_regfile.v` |
| 顶层集成 | `top/dev` | `soc_top.v`, `ahb_matrix.v`, `ahb2apb_bridge.v` |

---

> 📢 **所有模块开发者请在开始编写 RTL 前确认理解以上接口规范，有问题及时在 Day 4-5 对齐会议上沟通。**
