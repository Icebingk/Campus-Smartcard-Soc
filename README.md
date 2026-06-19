# 校园智能卡 SoC — 项目说明书

> **项目**: 基于 SoC 的校园智能卡主芯片设计
> **工艺**: 数字 ASIC 正向设计全流程 (RTL → GDSII)
> **最后更新**: 2026-06-20
> **当前阶段**: Phase 4 — 三大核心模块 RTL 完成 + 仿真 70 项全通过 + 综合通过 ✅

---

## 1. 项目结构

```
Campus-Smartcard-Soc/
├── README.md                    # 本文件（项目首页）
├── doc/                         # 文档
│   ├── README.md                # 同上（副本）
│   ├── memory_map.md            # 全芯片地址映射（必读）
│   └── interface_spec.md        # 模块接口信号规范（必读）
├── rtl/                         # RTL 源代码
│   ├── top/soc_top.v            # 顶层集成 ✅
│   ├── bus/                     # AMBA 总线 ✅
│   │   ├── ahb_matrix.v         #   AHB-Lite 1×3 总线矩阵
│   │   ├── ahb2apb_bridge.v     #   AHB→APB 桥 (v2.0)
│   │   └── apb_regfile_template.v
│   ├── cpu/                     # CPU (双轨: 仿真/综合) ✅
│   │   ├── picorv32.v           #   开源 PicoRV32 核 (YosysHQ, ISC)
│   │   ├── rv32ec_core.v        #   AHB-Lite 适配 wrapper (综合用)
│   │   └── rv32ec_bfm.v         #   行为模型备份 (仿真用)
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
├── syn/                         # 综合环境
│   ├── constraints/
│   │   └── soc_timing.xdc        #   时序约束 (13.56MHz)
│   ├── scripts/
│   │   ├── create_project.tcl    #   Vivado 工程创建
│   │   └── synthesis.tcl         #   综合脚本
│   ├── vivado/                   #   Vivado 项目 (.gitignore)
│   └── outputs/                  #   综合输出 (.gitignore)
├── 需求安排.txt
└── .gitignore
```

---

## 2. 快速开始

### 2.1 环境要求

| 工具           | 版本    | 用途     |
| -------------- | ------- | -------- |
| ModelSim SE-64 | 2020.4+ | RTL 仿真 |
| Vivado         | 2022.2+ | 逻辑综合 |

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

**全芯片仿真结果** (70 项测试, 17 大类):

| #  | 测试类别             | 项数 | 典型验证点                                     |
| -- | -------------------- | ---- | ---------------------------------------------- |
| 1  | ROM 多字读取         | 2    | ROM[0], ROM[1]                                 |
| 2  | SRAM 多地址+边界     | 4    | SRAM[0], SRAM[1], SRAM[511], 回读保护          |
| 3  | 基带全寄存器         | 4    | CTRL, TX_DATA, INT_EN, BAUD_CFG                |
| 4  | AES 全密钥寄存器     | 5    | KEY0~3 + 回读确认未串扰                        |
| 5  | EEPROM 全寄存器      | 4    | CTRL, ADDR, WDATA, LEN                         |
| 6  | 边界地址             | 4    | 0x40000FFC, 0x40001000, 0x80000000, 0xFFFFFFFF |
| 7  | Walking 数据完整性   | 5    | Walking-1/0, All-1/0, 0x55555555               |
| 8  | 背靠背连续访问       | 4    | 连续写读 SRAM[8..11]                           |
| 9  | 交叉外设交替访问     | 4    | 基带→AES→EEPROM→基带 交替读写               |
| 10 | AES 全 16 寄存器压力 | 16   | 全部 16 寄存器连续写入+全部回读                |
| 11 | 地址空间间隙         | 3    | ROM-SRAM 间隙, APB 未用区                      |
| 12 | 同地址反复覆写       | 1    | 覆写 4 次验证最终值                            |
| 13 | APB 地址别名         | 2    | 外设 4KB 空间内地址回绕                        |
| 14 | **AES-128 加密**     | 4    | FIPS-197 标准向量 (key/plain/cipher)           |
| 15 | **AES-128 解密**     | 4    | 密文解密恢复明文                               |
| 16 | **基带 FIFO 功能**   | 2    | TX 数据推送、发送完成                          |
| 17 | **EEPROM I2C 配置**  | 2    | 分频寄存器、设备地址配置                       |

```bash
# 运行全芯片仿真
cd sim/scripts
vsim -c -do sim_top.do

# 预期输出
# [CPU] ===== 自检完成 =====
# [CPU] 通过: 70, 失败: 0
# [CPU] *** 所有测试通过! ***
```

---

## 3. 模块状态

| 模块              | 文件                               | 状态      | 负责人   |
| ----------------- | ---------------------------------- | --------- | -------- |
| AHB 总线矩阵      | `rtl/bus/ahb_matrix.v`           | ✅ 完成   | 阿呆不呆 |
| AHB2APB 桥        | `rtl/bus/ahb2apb_bridge.v`       | ✅ v2.0   | 阿呆不呆 |
| APB 寄存器模板    | `rtl/bus/apb_regfile_template.v` | ✅ 完成   | 阿呆不呆 |
| ROM 16KB          | `rtl/mem/rom_model.v`            | ✅ 完成   | 阿呆不呆 |
| SRAM 8KB          | `rtl/mem/sram_model.v`           | ✅ 完成   | 阿呆不呆 |
| CPU (PicoRV32)    | `rtl/cpu/picorv32.v`             | ✅ 集成   | 阿呆不呆 |
| CPU (AHB Wrapper) | `rtl/cpu/rv32ec_core.v`          | ✅ 完成   | 阿呆不呆 |
| CPU (BFM 备份)    | `rtl/cpu/rv32ec_bfm.v`           | ✅ 保留   | 阿呆不呆 |
| PMU               | `rtl/pmu/pmu_top.v`              | ✅ 完成   | 陆凤敏   |
| SoC 顶层集成      | `rtl/top/soc_top.v`              | ✅ 完成   | 阿呆不呆 |
| 全芯片 Testbench  | `sim/tb/tb_soc_top.v`            | ✅ 完成   | 阿呆不呆 |
| 数字基带          | `rtl/baseband/bb_top.v`          | ✅ v1.0  | 阿呆不呆 |
| AES-128           | `rtl/aes/aes_top.v`              | ✅ v1.0  | 阿呆不呆 |
| EEPROM 控制器     | `rtl/eeprom/eep_top.v`           | ✅ v1.0  | 阿呆不呆 |
| Memory Map        | `doc/memory_map.md`              | ✅ v1.0  | 何展韬   |
| 接口规范          | `doc/interface_spec.md`          | ✅ v1.0  | 何展韬   |
| 芯片 Spec         | `doc/`                           | ✅ 完成  | 何展韬   |
| 项目甘特图        | —                                | ⚠️ 待定 | 何展韬   |

---

## 4. 综合结果 (Vivado 2022.2, Artix-7 xc7a35tcsg324-1)

| 指标 | 值 |
|------|-----|
| **Target** | Artix-7 xc7a35tcsg324-1 (FPGA Prototype) |
| **Clock** | 13.56 MHz (period 73.746 ns) |
| **WNS** | +27.646 ns ✅ |
| **TNS** | 0.000 ns ✅ |
| **Failing Endpoints** | 0 ✅ |

### 资源利用率

| 资源 | 用量 | 可用 | 利用率 |
|------|------|------|--------|
| **LUT** (LUT4+LUT6+LUT5+LUT3+LUT2+LUT1) | 3,855 | 20,800 | **18.5%** |
| **FF** (FDCE+FDRE+FDSE+FDPE) | 1,625 | 41,600 | **3.9%** |
| **Distributed RAM** (RAMS64E+RAMD32+RAMS32) | 1,112 | — | — |
| **Carry Chain** (CARRY4) | 71 | — | — |
| **BUFG** | 1 | 32 | 3.1% |
| **IO** | 6 | 210 | 2.9% |

### 功耗估算

| 项目 | 值 |
|------|-----|
| **Total On-Chip Power** | 77 mW |
| Dynamic Power | 6 mW |
| Static Power | 70 mW |
| Junction Temp | 25.4°C |

---

## 5. 团队分工

| 成员               | 角色         | 核心任务                              |
| ------------------ | ------------ | ------------------------------------- |
| **阿呆不呆** | 集成负责人   | SoC 顶层、AMBA 总线、Memory Map、综合 |
| **林子轩**   | 数字基带     | ISO14443 防冲突 FSM、曼彻斯特编解码   |
| **梁芷晴**   | 加密引擎     | 迭代型 AES-128 协处理器               |
| **陆凤敏**   | 后端物理设计 | SDC、IR-Drop、电源网络                |
| **何展韬**   | 整体设计     | 芯片 Spec、软硬件划分、微架构拓扑、接口标准、甘特图 |

---

## 6. 给模块开发者的接口规范

### 6.1 APB 从机必选端口

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

### 6.2 注意事项

- **地址偏移**: 严格遵循 [`memory_map.md`](doc/memory_map.md)
- **写时序**: 建议 `negedge pclk` 采样 `psel && penable && pwrite`
- **读时序**: 组合逻辑输出，`psel && !pwrite` 时返回 `regfile[addr]`
- 详细规范见 [`interface_spec.md`](doc/interface_spec.md)

---

## 7. 时间节点

| 日期      | 事项                       | 状态            |
| --------- | -------------------------- | --------------- |
| Day 1     | 需求定义 & 技术选型        | ✅              |
| Day 3     | Memory Map v1.0 发布       | ✅              |
| Day 5     | 接口规范 & 团队对齐        | ✅              |
| Day 7     | 总线 + Bridge RTL 完成     | ✅              |
| Day 10    | 全芯片集成 & 58 项仿真通过 | ✅              |
| Day 11    | PicoRV32 开源核集成        | ✅              |
| Day 12    | Vivado 综合流程打通        | ✅              |
| Week 2 末 | 模块 RTL 交付              | 待林子轩/梁芷晴 |
| Week 3    | FPGA 实现 (P&R)            | 待启动          |
| Week 4    | 最终网表交付               | 待启动          |

---

## 8. 团队协作指南

### 8.1 克隆仓库

**方式一：SSH（推荐，无需反复输密码）**

```bash
git clone git@github.com:Icebingk/Campus-Smartcard-Soc.git
cd Campus-Smartcard-Soc
```

**方式二：HTTPS（备用）**

```bash
git clone https://github.com/Icebingk/Campus-Smartcard-Soc.git
cd Campus-Smartcard-Soc
```

### 8.2 配置 SSH Key（仅首次，一次性）

打开终端（Git Bash 或 PowerShell），生成 SSH 密钥：

```bash
ssh-keygen -t ed25519 -C "1520349663@qq.com"
# 一路回车即可（默认路径，不设密码）
```

复制公钥：

```bash
cat ~/.ssh/id_ed25519.pub
```

将输出的内容添加到 GitHub：

1. 登录 GitHub → 右上角头像 → **Settings**
2. 左侧菜单 → **SSH and GPG keys**
3. 点击 **New SSH key**
4. Title 随便填（如"我的电脑"），Key 粘贴公钥内容
5. 点击 **Add SSH key**

验证是否配置成功：

```bash
ssh -T git@github.com
# 预期输出: Hi Icebingk! You've successfully authenticated...
```

### 8.3 分支策略

```
master（主分支）—— 始终保持稳定、可综合、仿真通过
  ├── bb/fsm       —— 林子轩：数字基带 FSM 开发
  ├── aes/iter     —— 梁芷晴：AES 迭代引擎开发
  ├── eep/ctrl     —— EEPROM 控制器开发
  └── pmu/pdn      —— 陆凤敏：电源网络/后端
```

**规则：**

- **master 分支禁止直接 push**（由队长阿呆不呆合并）
- 每人从 master 拉自己的功能分支开发
- 模块验证通过后，提 Pull Request 合并回 master

### 8.4 日常协作流程

**① 首次：克隆仓库**

```bash
git clone git@github.com:Icebingk/Campus-Smartcard-Soc.git
cd Campus-Smartcard-Soc
```

**② 创建自己的功能分支**

```bash
git checkout -b 你的分支名
# 例如:
# 林子轩: git checkout -b bb/fsm
# 梁芷晴: git checkout -b aes/iter
```

**③ 日常开发**

```bash
# 写代码...

# 查看改了哪些文件
git status

# 添加修改
git add rtl/你的模块/*.v

# 提交（写清楚改了什么）
git commit -m "feat: 完成曼彻斯特解码状态机"

# 推送自己的分支到 GitHub
git push -u origin 你的分支名
```

**④ 后续每次写代码前，先同步 master 最新代码**

```bash
git checkout master
git pull
git checkout 你的分支名
git merge master
```

**⑤ 模块完成后，在 GitHub 网页提 Pull Request**

1. 打开 https://github.com/Icebingk/Campus-Smartcard-Soc
2. 点击 **Pull requests** → **New pull request**
3. base 选 `master`，compare 选你的分支
4. 点击 **Create pull request**，填写说明
5. 通知阿呆不呆 Review 并合并

### 8.5 提交信息规范

遵循约定式提交格式：

| 前缀          | 用途             | 示例                                |
| ------------- | ---------------- | ----------------------------------- |
| `feat:`     | 新功能/新模块    | `feat: 添加防冲突 FSM 状态机`     |
| `fix:`      | 修 Bug           | `fix: 修复 APB 读数据延迟一拍`    |
| `docs:`     | 文档更新         | `docs: 更新 memory_map 地址分配`  |
| `refactor:` | 重构（不改功能） | `refactor: 优化 AHB 仲裁逻辑`     |
| `sim:`      | 仿真/测试相关    | `sim: 新增基带寄存器读写测试用例` |
| `syn:`      | 综合相关         | `syn: 更新时序约束 13.56MHz`      |

### 8.6 注意事项

- `sim/scripts/work/`、`syn/vivado/`、`syn/outputs/` 等临时文件已加入 `.gitignore`，不会被提交
- 仿真波形文件（`.wlf`、`.vcd`）不要提交，体积太大
- 如果遇到合并冲突，先和队长沟通，不要强制覆盖
- 有问题随时在群里 @阿呆不呆
