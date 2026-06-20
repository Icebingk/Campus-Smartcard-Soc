#!/bin/bash
# ================================================================
# 校园智能卡 SoC — ASIC 后端一键运行脚本
# Usage: bash run_all.sh
# ================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo " 校园智能卡 SoC — ASIC 后端全流程"
echo " TSMC 90nm | DC → ICC2 → PT → FM"
echo "=========================================="

# ================================================================
# 1. Design Compiler 综合
# ================================================================
echo ""
echo "[1/4] Running Design Compiler synthesis..."
dc_shell -f dc_synthesis.tcl | tee ../reports/dc_synthesis.log
echo "  [OK] DC synthesis done"

# ================================================================
# 2. ICC2 布局布线
# ================================================================
echo ""
echo "[2/4] ICC2 Place & Route (需要 Milkyway 库)..."
echo "  icc2_shell -f icc2_flow.tcl | tee ../reports/icc2_flow.log"

# ================================================================
# 3. PrimeTime STA
# ================================================================
echo ""
echo "[3/4] PrimeTime Static Timing Analysis..."
echo "  pt_shell -f pt_sta.tcl | tee ../reports/pt_sta.log"

# ================================================================
# 4. Formality 形式验证
# ================================================================
echo ""
echo "[4/4] Formality Equivalence Check..."
echo "  fm_shell -f fm_check.tcl | tee ../reports/fm_check.log"

echo ""
echo "=========================================="
echo " DC 综合完成! 查看报告:"
echo "   less ../reports/dc_area.rpt"
echo "   less ../reports/dc_timing.rpt"
echo "=========================================="
