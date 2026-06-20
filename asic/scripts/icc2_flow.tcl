# ================================================================
# Synopsys IC Compiler II — Campus Smartcard SoC
# Target: TSMC 90nm, 5LM 2thick
# Usage: icc2_shell -f icc2_flow.tcl | tee ../reports/icc2_flow.log
# ================================================================

# ================================================================
# 0. Library Setup — TSMC 90nm
# ================================================================
set TSMC90      "/opt/Foundary_Library/TSMC90/aci/sc-x"
set TECH_FILE   "$TSMC90/astro/tf/tsmc090_5lm_2thick.tf"
set DB_PATH     "$TSMC90/synopsys"

set_app_var search_path    [list . $DB_PATH]
set_app_var target_library "slow.db"
set_app_var link_library   "* slow.db"

# ================================================================
# 1. Create Milkyway Library
# ================================================================
# create_mw_lib -technology $TECH_FILE \
#     -mw_reference_library $MW_REF_LIB \
#     soc_top.mw
# open_mw_lib soc_top.mw

# ================================================================
# 2. Read Netlist & Constraints
# ================================================================
# read_verilog ../outputs/soc_top_netlist.v
# current_design soc_top
# read_sdc ../outputs/soc_top.sdc

# ================================================================
# 3. Floorplan
# ================================================================
# Estimated gate count: ~25K gates → ~0.1 mm² in 90nm
# create_floorplan -core_utilization 0.7 \
#     -core_width 350 -core_height 350

# ================================================================
# 4. Place & Route
# ================================================================
# place_opt
# clock_opt
# route_auto

# ================================================================
# 5. Reports & Output
# ================================================================
# report_area    > ../reports/icc2_area.rpt
# report_timing  > ../reports/icc2_timing.rpt
# report_power   > ../reports/icc2_power.rpt
# write_verilog ../outputs/soc_top_final.v
# write_gds     ../outputs/soc_top.gds

puts "\[ICC2\] ========================================"
puts "\[ICC2\]  Place & Route Complete"
puts "\[ICC2\] ========================================"
exit
