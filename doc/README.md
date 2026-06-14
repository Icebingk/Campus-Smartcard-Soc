# 校园智能卡 SoC 项目说明书

> **项目**: 基于 SoC 的校园智能卡主芯片设计  
> **工程阶段**: Phase 1-2 (基础设施构建)  
> **最后更新**: 2026-06-14  

---

## 1. 项目结构

```
Soc/
├── doc/                    # 文档
│   ├── memory_map.md       # 全芯片地址映射（必读）
│   ├── interface_spec.md   # 接口信号规范（必读）
│   └── README.md           # 本文件
├── rtl/                    # RTL 源代码
│   ├── top/                # 顶层集成（待编写）
│   ├── bus/                # 总线 (完成)
│   │   ├── ahb_matrix.v
│   │   ├── ahb2apb_bridge.v
│   │   └── apb_regfile_template.v
│   ├── cpu/                # 处理器核 (外采)
│   ├── mem/                # 存储器 (完成)
│   │   ├── rom_model.v
│   │   └── sram_model.v
│   ├── baseband/           # 数字基带 (林子轩)
│   ├── aes/                # AES 引擎 (梁芷晴)
│   ├── eeprom/             # EEPROM 控制器
│   └── pmu/                # 电源管理 (时钟门控)
├── sim/                    # 仿真环境
│   ├── tb/                 # Testbench
│   │   ├── tb_ahb_bus.v    # AHB 总线测试
│   │   ├── ahb_master_bfm.v
│   │   └── tb_soc_top.v    # 全芯片测试 (待编写)
│   └── scripts/            # 仿真脚本
│       ├── sim_bus.do      # ModelSim 运行脚本
│       └── sim_top.do
├── syn/                    # 综合环境
│   └── scripts/
│       └── synthesis.tcl   # Vivado TCL 脚本
└── .gitignore
```

---

## 2. 快速开始

### 2.1 仿真 AHB 总线 (ModelSim)

```bash
cd sim/scripts
vsim -do sim_bus.do
```

**预期输出**:
- ROM 读取: 0x00000001
- SRAM 写入 + 读回: 0xDEAD_BEEF
- APB Bridge 回路: 0x00000001
- 地址越界: 0xDEAD_BEEF (ERROR)

### 2.2 综合全芯片 (Vivado)

```bash
cd syn/scripts
vivado -mode batch -source synthesis.tcl
```

**输出**: `syn/outputs/` 目录下的网表和报告

---

## 3. 文件状态

| 模块 | 文件 | 状态 | 负责人 |
|------|------|------|--------|
| AHB 总线 | `rtl/bus/ahb_matrix.v` | ✅ 完成 | 阿呆不呆 |
| AHB2APB | `rtl/bus/ahb2apb_bridge.v` | ✅ 完成 | 阿呆不呆 |
| APB 模板 | `rtl/bus/apb_regfile_template.v` | ✅ 完成 | 阿呆不呆 |
| ROM | `rtl/mem/rom_model.v` | ✅ 完成 | 阿呆不呆 |
| SRAM | `rtl/mem/sram_model.v` | ✅ 完成 | 阿呆不呆 |
| 数字基带 | `rtl/baseband/` | ⏳ 开发中 | 林子轩 |
| AES-128 | `rtl/aes/` | ⏳ 开发中 | 梁芷晴 |
| 顶层 | `rtl/top/soc_top.v` | ⏳ 待编写 | 阿呆不呆 |
| 全芯片测试 | `sim/tb/tb_soc_top.v` | ⏳ 待编写 | 阿呆不呆 |

---

## 4. 接口对接指南（给团队成员）

### 4.1 数字基带 (林子轩) 开发检查清单

- [ ] 模块顶层端口**必须**包含: `pclk, presetn, psel, penable, paddr, pwrite, pwdata, prdata, pready, pslverr, irq_o`
- [ ] 地址偏移遵循 `doc/memory_map.md` 第 3.1 节
  - `0x000`: BB_CTRL
  - `0x004`: BB_STATUS
  - `0x008` 之后: TX_DATA/RX_DATA/FIFO_LEVEL 等
- [ ] 在 `apb_regfile_template.v` 基础上扩展，或参考其寄存器读写逻辑
- [ ] 中断输出 `irq_o` 连接到顶层中断聚合电路

### 4.2 AES-128 引擎 (梁芷晴) 开发检查清单

- [ ] 同样遵循 APB 从机端口规范
- [ ] 地址偏移: `doc/memory_map.md` 第 3.2 节
  - 0x000 ~ 0x014: 控制 + 密钥 (4 x 32-bit)
  - 0x018 ~ 0x024: 明文/密文输入 (4 x 32-bit)
  - 0x028 ~ 0x034: 结果输出 (4 x 32-bit)
- [ ] 使用迭代型架构，门数 < 4000
- [ ] 中断输出连接到顶层

---

## 5. 关键时间节点

| 日期 | 事项 | 所有者 |
|------|------|--------|
| **Day 3** | Memory Map v1.0 发布 | 阿呆不呆 ✅ |
| **Day 5** | 接口规范 v1.0 + 团队对齐会 | 阿呆不呆 ✅ |
| **Week 2 末** | 模块 RTL 交付底线 | 林子轩, 梁芷晴 |
| **Week 3 中** | 全芯片集成完成 | 阿呆不呆 |
| **Week 3 末** | 全芯片仿真通过 | 阿呆不呆 |
| **Week 4 初** | 综合首轮 | 阿呆不呆 + 陆凤敏 |
| **Week 4 末** | 最终交付 | 全员 |

---

## 6. 常见问题

### Q: 如何修改 ROM 初始化内容?
**A**: 编辑 `rtl/mem/rom_model.v` 中 `initial` 块，或使用 $readmemh() 从文件加载。

### Q: 仿真报错 "NONSEQ transaction not completed"?
**A**: 检查 Slave 的 `hready` 信号，应在每个传输完成后拉高。

### Q: 如何添加新的 APB 从机?
**A**: 
1. 在 `memory_map.md` 中分配地址
2. 在 `ahb_matrix.v` 中添加 `hsel_xxx` 译码规则
3. 模块实现 APB Slave 接口

### Q: 综合时报警 "Some constraints not met"?
**A**: 检查 `syn/scripts/synthesis.tcl` 中的时钟周期设置，可能需要降频或优化 RTL。

---

## 7. 参考资源

- **AMBA AHB-Lite Spec**: 用于总线设计参考
- **APB Slave 接口规范**: 见 `doc/interface_spec.md`
- **Memory Map**: 见 `doc/memory_map.md`

---

> 📢 **最后更新**: 2026-06-14  
> **维护人**: 阿呆不呆  
> **如有疑问，请及时沟通！**
