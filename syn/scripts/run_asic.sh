#!/bin/bash
# ================================================================
# 校园智能卡 SoC — ASIC 后端一键运行脚本
# Usage: bash run_asic.sh
# ================================================================
set -e

echo "=========================================="
echo " 校园智能卡 SoC — ASIC 后端全流程"
echo " TSMC 90nm | DC + ICC2"
echo "=========================================="

# 克隆项目 (如果还没 clone)
if [ ! -d "Campus-Smartcard-Soc" ]; then
    git clone git@github.com:Icebingk/Campus-Smartcard-Soc.git
fi
cd Campus-Smartcard-Soc/syn/scripts

# ================================================================
# 1. DC 综合
# ================================================================
echo ""
echo "[1/4] Running Design Compiler synthesis..."
dc_shell -f dc_synthesis.tcl | tee dc_synthesis.log

# 检查是否成功
if grep -q "Synthesis Complete" dc_synthesis.log; then
    echo "  [OK] DC synthesis passed"
else
    echo "  [FAIL] DC synthesis failed, check dc_synthesis.log"
    exit 1
fi

# ================================================================
# 2. ICC2 布局布线 (需要 Milkyway 库)
# ================================================================
echo ""
echo "[2/4] Running ICC2 place & route..."
echo "  Note: 需要先生成 Milkyway 参考库"
echo "  icc2_shell -f icc2_flow.tcl | tee icc2_flow.log"

# ================================================================
# 3. PrimeTime 静态时序分析
# ================================================================
echo ""
echo "[3/4] PrimeTime STA (手动运行):"
echo "  pt_shell -f pt_sta.tcl"

# ================================================================
# 4. Formality 形式验证
# ================================================================
echo ""
echo "[4/4] Formality 等价性检查 (手动运行):"
echo "  fm_shell -f fm_check.tcl"

echo ""
echo "=========================================="
echo " ASIC 流程脚本已准备就绪"
echo "=========================================="
