# 校园智能卡 SoC — 项目说明书

> **项目**: 基于 SoC 的校园智能卡主芯片设计  
> **工艺**: 数字 ASIC 正向设计全流程 (RTL → GDSII)  
> **最后更新**: 2026-06-14  
> **当前阶段**: Phase 2 — 全芯片集成验证通过 ✅

---

## 1. 项目结构

```
Campus-Smartcard-Soc/
├── doc/                         # 文档
│   ├── README.md                # 本文件
│   ├── memory_map.md            # 全芯片地址映射（必读）
│   └── interface_spec.md        # 模块接口信号规范（必读）
├── rtl/                         # RTL 源代码
│   ├── top/soc_top.v            # 顶层集成 ✅
│   ├── bus/                     # AMBA 总线 ✅
│   │   ├── ahb_matrix.v         #   AHB-Lite 1×3 总线矩阵
│   │   ├── ahb2apb_bridge.v     #   AHB→APB 桥 (v2.0)
│   │   └── apb_regfile_template.v
│   ├── cpu/rv32ec_core.v        # CPU 行为模型 (AHB Master) ✅
│   ├── mem/                     # 存储器 ✅
│   │   ├── rom_model.v          #   ROM 16KB (AHB Slave)
│   │   └── sram_model.v         #   SRAM 8KB (AHB Slave)
│   ├── baseband/bb_top.v        # 数字基带 APB 存根 ⚠️ 待林子轩
│   ├── aes/aes_top.v            # AES-128 APB 存根 ⚠️ 待梁芷晴
│   ├── eeprom/eep_top.v         # EEPROM 控制器存根 ⚠️
│   └── pmu/pmu_top.v            # 电源管理 (时钟门控+复位同步) ✅
├── sim/                         # 仿真环境
│   ├── tb/
│   │   ├── tb_ahb_bus.v         #   AHB 总线单元测试 ✅
│   │   ├── tb_soc_top.v         #   全芯片测试 ✅
│   │   └── ahb_master_bfm.v     #   AHB Master BFM
│   └── scripts/
│       ├── sim_bus.do            #   ModelSim 总线仿真脚本
│       └── sim_top.do            #   ModelSim 全芯片仿真脚本
├── syn/scripts/                 # 综合环境
│   ├── create_project.tcl
│   └── synthesis.tcl
└── .gitignore
```

---

## 2. 快速开始

### 2.1 环境要求

| 工具 | 版本 | 用途 |
|------|------|------|
| ModelSim SE-64 | 2020.4+ | RTL 仿真 |
| Vivado | 2020.2+ | 逻辑综合 |

### 2.2 运行仿真

```bash
# 总线级仿真 (AHB Matrix + Bridge + ROM + SRAM)
cd sim/scripts
vsim -c -do sim_bus.do

# 全芯片仿真 (CPU + 总线 + 所有外设)  
cd sim/scripts
vsim -c -do sim_top.do

# GUI 波形模式
cd sim/scripts
vsim -do sim_top.do
```

**全芯片仿真结果** (10/10 通过):

| # | 测试 | 结果 |
|---|------|------|
| 1 | ROM 读 @ 0x00000000 | `0x00000001` ✅ |
| 2 | SRAM 写 @ 0x00010000 | `0xCAFEBABE` ✅ |
| 3 | SRAM 读验证 | `0xCAFEBABE` ✅ |
| 4 | 基带 CTRL 写 | `0x00000001` ✅ |
| 5 | 基带 CTRL 读 | `0x00000001` ✅ |
| 6 | AES KEY0 写 | `0x2B7E1516` ✅ |
| 7 | AES KEY0 读 | `0x2B7E1516` ✅ |
| 8 | EEPROM CTRL 写 | `0x00000003` ✅ |
| 9 | EEPROM CTRL 读 | `0x00000003` ✅ |
| 10 | 地址越界 | `0xDEAD_BEEF` ✅ |

---

## 3. 模块状态

| 模块 | 文件 | 状态 | 负责人 |
|------|------|------|--------|
| AHB 总线矩阵 | `rtl/bus/ahb_matrix.v` | ✅ 完成 | 阿呆不呆 |
| AHB2APB 桥 | `rtl/bus/ahb2apb_bridge.v` | ✅ v2.0 | 阿呆不呆 |
| APB 寄存器模板 | `rtl/bus/apb_regfile_template.v` | ✅ 完成 | 阿呆不呆 |
| ROM 16KB | `rtl/mem/rom_model.v` | ✅ 完成 | 阿呆不呆 |
| SRAM 8KB | `rtl/mem/sram_model.v` | ✅ 完成 | 阿呆不呆 |
| CPU (行为模型) | `rtl/cpu/rv32ec_core.v` | ✅ 存根 | 阿呆不呆 |
| PMU | `rtl/pmu/pmu_top.v` | ✅ 完成 | 陆凤敏 |
| SoC 顶层集成 | `rtl/top/soc_top.v` | ✅ 完成 | 阿呆不呆 |
| 全芯片 Testbench | `sim/tb/tb_soc_top.v` | ✅ 完成 | 阿呆不呆 |
| 数字基带 | `rtl/baseband/bb_top.v` | ⚠️ 存根 | 林子轩 |
| AES-128 | `rtl/aes/aes_top.v` | ⚠️ 存根 | 梁芷晴 |
| EEPROM 控制器 | `rtl/eeprom/eep_top.v` | ⚠️ 存根 | — |

---

## 4. 团队分工

| 成员 | 角色 | 核心任务 |
|------|------|---------|
| **阿呆不呆** | 集成负责人 | SoC 顶层、AMBA 总线、Memory Map、综合 |
| **林子轩** | 数字基带 | ISO14443 防冲突 FSM、曼彻斯特编解码 |
| **梁芷晴** | 加密引擎 | 迭代型 AES-128 协处理器 |
| **陆凤敏** | 后端物理设计 | SDC、IR-Drop、电源网络 |
| **何展韬** | 整体设计 | Spec、软硬件划分、微架构 |

---

## 5. 给模块开发者的接口规范

### 5.1 APB 从机必选端口

```verilog
module your_module (
    input  wire         pclk,        // APB 时钟
    input  wire         presetn,     // APB 复位
    input  wire         psel,        // 从机选择
    input  wire         penable,     // APB 使能
    input  wire [11:0]  paddr,       // 地址 (12-bit)
    input  wire         pwrite,      // 1=写, 0=读
    input  wire [31:0]  pwdata,      // 写数据
    output wire [31:0]  prdata,      // 读数据
    output wire         pready,      // 就绪 (=1)
    output wire         pslverr,     // 错误 (=0)
    output wire         irq_o         // 中断
);
```

### 5.2 注意事项

- **地址偏移**: 严格遵循 [`memory_map.md`](memory_map.md)
- **写时序**: 建议 `negedge pclk` 采样 `psel && penable && pwrite`
- **读时序**: 组合逻辑输出，`psel && !pwrite` 时返回 `regfile[addr]`
- 详细规范见 [`interface_spec.md`](interface_spec.md)

---

## 6. 时间节点

| 日期 | 事项 | 状态 |
|------|------|------|
| Day 1 | 需求定义 & 技术选型 | ✅ |
| Day 3 | Memory Map v1.0 发布 | ✅ |
| Day 5 | 接口规范 & 团队对齐 | ✅ |
| Day 7 | 总线 + Bridge RTL 完成 | ✅ |
| Day 10 | 全芯片集成 & 仿真通过 | ✅ |
| Week 2 末 | 模块 RTL 交付 | 待林子轩/梁芷晴 |
| Week 3 | 综合首轮 | 待启动 |
| Week 4 | 最终网表交付 | 待启动 |
