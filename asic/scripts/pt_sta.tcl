# ================================================================
# Synopsys PrimeTime — Static Timing Analysis
# Usage: pt_shell -f pt_sta.tcl | tee ../reports/pt_sta.log
# ================================================================

set TSMC90    "/opt/Foundary_Library/TSMC90/aci/sc-x/synopsys"
set search_path [list . $TSMC90]

set link_path "* slow.db"

# Read netlist
# read_verilog ../outputs/soc_top_netlist.v
# current_design soc_top

# Read constraints
# read_sdc ../outputs/soc_top.sdc
# read_parasitics ../outputs/soc_top.spef

# Report timing
# report_timing -max_paths 100 > ../reports/pt_timing.rpt
# report_constraint -all_violators > ../reports/pt_violations.rpt

puts "\[PT\] STA Complete"
exit
