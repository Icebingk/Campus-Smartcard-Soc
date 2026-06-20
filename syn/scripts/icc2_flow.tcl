# ================================================================
# Synopsys IC Compiler II — Campus Smartcard SoC
# ================================================================
# Usage: icc2_shell -f icc2_flow.tcl | tee icc2_flow.log
# ================================================================

# ================================================================
# 0. Library Setup (根据 VM 上的路径修改)
# ================================================================
# TODO: 替换为实际路径
set LIB_PATH "/path/to/your/technology/lib"
set MW_REF_PATH "$LIB_PATH/milkyway"

# set_app_var search_path [list . $LIB_PATH $MW_REF_PATH]
# set_app_var target_library   "your_std_cell_ss.db"
# set_app_var link_library     "* $target_library"

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
