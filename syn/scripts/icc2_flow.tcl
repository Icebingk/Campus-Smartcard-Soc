# ================================================================
# Synopsys IC Compiler II — Campus Smartcard SoC
# Target: TSMC 90nm, 5LM 2thick
# Usage: icc2_shell -f icc2_flow.tcl | tee icc2_flow.log
# ================================================================

# ================================================================
# 0. Library Setup — TSMC 90nm (5 metal layers, 2 thick metals)
# ================================================================
set TSMC90      "/opt/Foundary_Library/TSMC90/aci/sc-x"
set TECH_FILE   "$TSMC90/astro/tf/tsmc090_5lm_2thick.tf"
set MW_REF_LIB  "$TSMC90/mw_lib"     ;# 需要先用 Milkyway 生成
set DB_PATH     "$TSMC90/synopsys"

set_app_var search_path      [list . $DB_PATH $MW_REF_LIB]
set_app_var target_library   "slow.db"
set_app_var link_library     "* slow.db"
set_app_var mw_reference_library ""

# Note: ICC2 需要 Milkyway 格式的参考库
# 如果 MW 库不存在，先用以下命令生成:
#   set mw_logic0_net $MW_REF_LIB
#   create_mw_lib -technology $TECH_FILE -mw_reference_library $MW_REF_LIB soc_top.mw

# ================================================================
# 1. Create Library & Read Netlist
# ================================================================
# create_mw_lib -technology $MW_REF_PATH/your_tech.tf \
#               -mw_reference_library $MW_REF_PATH/your_std_cell \
#               soc_top.mw
# open_mw_lib soc_top.mw

# Read synthesized netlist
# read_verilog ../outputs/soc_top_netlist.v
# current_design soc_top

# Read constraints
# read_sdc ../outputs/soc_top.sdc

# ================================================================
# 2. Floorplan
# ================================================================
# Create floorplan (estimated ~0.5 mm² for 25K gates in 65nm)
# create_floorplan -core_utilization 0.7 \
#                  -core_width 800 -core_height 600 \
#                  -start_first_row -flip_first_row

# Place IO pads
# ...

# ================================================================
# 3. Place
# ================================================================
# place_opt

# ================================================================
# 4. Clock Tree Synthesis
# ================================================================
# clock_opt

# ================================================================
# 5. Route
# ================================================================
# route_auto

# ================================================================
# 6. Reports
# ================================================================
# report_area    > ../outputs/icc2_area.rpt
# report_timing  > ../outputs/icc2_timing.rpt
# report_power   > ../outputs/icc2_power.rpt
# report_qor     > ../outputs/icc2_qor.rpt

# ================================================================
# 7. Output GDSII
# ================================================================
# write_verilog ../outputs/soc_top_final.v
# write_gds      ../outputs/soc_top.gds
# write_def      ../outputs/soc_top.def

puts "\[ICC2\] ===== Place & Route Complete ====="
exit
