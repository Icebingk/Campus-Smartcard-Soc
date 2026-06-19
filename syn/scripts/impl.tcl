# ================================================================
# Vivado Implementation (Place & Route) — Campus Smartcard SoC
# Usage: vivado -mode batch -source create_project.tcl -source synthesis.tcl -source impl.tcl
# ================================================================

set out_dir  "../outputs"

puts "\[IMPL\] Running implementation..."

# ================================================================
# 1. Optimization
# ================================================================
opt_design
puts "\[IMPL\] opt_design done"

# ================================================================
# 2. Placement
# ================================================================
place_design
puts "\[IMPL\] place_design done"

# ================================================================
# 3. Physical Optimization (optional, for timing closure)
# ================================================================
phys_opt_design
puts "\[IMPL\] phys_opt_design done"

# ================================================================
# 4. Routing
# ================================================================
route_design
puts "\[IMPL\] route_design done"

# ================================================================
# 5. Reports
# ================================================================
report_timing_summary -file $out_dir/timing_impl.rpt -max_paths 100
puts "\[IMPL\] -> timing_impl.rpt"

report_utilization -file $out_dir/utilization_impl.rpt
puts "\[IMPL\] -> utilization_impl.rpt"

report_power -file $out_dir/power_impl.rpt
puts "\[IMPL\] -> power_impl.rpt"

report_clock_networks -file $out_dir/clock_networks_impl.rpt
puts "\[IMPL\] -> clock_networks_impl.rpt"

report_drc -file $out_dir/drc_impl.rpt
puts "\[IMPL\] -> drc_impl.rpt"

# ================================================================
# 6. Generate Bitstream
# ================================================================
write_bitstream -force $out_dir/soc_top.bit
puts "\[IMPL\] -> soc_top.bit"

puts "\[IMPL\] ===== Implementation Complete ====="
