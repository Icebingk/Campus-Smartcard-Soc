# ASIC 后端流程 — VM 设置指南

## 1. 找到你的工具和库

登录学校 VM，依次执行：

```bash
# --- 确认工具可用 ---
which dc_shell         # Synopsys Design Compiler
which icc2_shell       # Synopsys ICC2
which design_vision    # GUI (可选)

# --- 找工艺库 ---
# 常见路径：
ls /opt/               # 很多学校装这里
ls /eda/               # 另一个常见位置
ls /home/tools/
ls /usr/local/foundry/

# 搜索 .db 文件 (Synopsys 库格式)
find /opt -name "*.db" 2>/dev/null | head -20
find /eda -name "*.db" 2>/dev/null | head -20

# 搜索标准单元库
find / -name "tcbn*"  2>/dev/null | head -10   # TSMC
find / -name "sc9*"   2>/dev/null | head -10   # SMIC
find / -name "gsclib*" 2>/dev/null | head -10  # GSMC
find / -name "saed*"  2>/dev/null | head -10   # SAED (教育用)

# --- 看有哪些工艺 ---
ls /opt/foundry/ 2>/dev/null
ls /eda/tsmc/    2>/dev/null
ls /eda/smic/    2>/dev/null
```

## 2. 把结果发给我

找到后，复制以下信息给我：

```bash
# 库文件列表
ls /你的库路径/

# .synopsys_dc.setup 或 .synopsys_icc2.setup 文件内容
cat ~/.synopsys_dc.setup 2>/dev/null
cat /你的库路径/.synopsys_dc.setup 2>/dev/null
```

## 3. 我需要知道的关键信息

| 问题 | 为什么重要 |
|------|-----------|
| 工艺节点 (65nm/55nm/40nm?) | 决定面积、功耗、频率 |
| 标准单元库名 (tcbn65gplus?) | DC 综合必需 |
| 是否有 Memory Compiler | ROM/SRAM 需要硬核替代 |
| IO Pad 库 | 芯片需要 IO Pad |
| Corner 类型 (ss/tt/ff) | ss=最慢 corner，签核用 |

## 4. 脚本位置

找到库后，修改这两个文件顶部的 `LIB_PATH`：

```
syn/scripts/dc_synthesis.tcl    ← DC 综合脚本
syn/scripts/icc2_flow.tcl       ← ICC2 布局布线脚本
```

## 5. 内存替换

ASIC 流程中，ROM/SRAM 不能用行为模型，需要用工艺库的 **Memory Compiler** 生成硬核。你 VM 上可能有类似：
```bash
find / -name "mc2" 2>/dev/null        # TSMC Memory Compiler
find / -name "smictool" 2>/dev/null   # SMIC Memory Compiler
```

生成后替换 `rtl/mem/rom_model.v` 和 `rtl/mem/sram_model.v`。
