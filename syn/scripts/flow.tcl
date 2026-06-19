# ================================================================
# Vivado Full Flow — Campus Smartcard SoC
# Usage: vivado -mode batch -source flow.tcl
# ================================================================

set project_name    "smart_card_soc"
set project_dir     "../vivado/[clock format [clock seconds] -format %Y%m%d_%H%M%S]"
set rtl_dir         "../../rtl"
set part            "xc7a35tcsg324-1"
set out_dir         "../outputs"

# ================================================================
# 1. Create Project
# ================================================================
create_project -force $project_name $project_dir -part $part
set_property target_language Verilog [current_project]
puts "\[FLOW\] Project created: $part"

# Add RTL
add_files -norecurse $rtl_dir/mem/rom_model.v
add_files -norecurse $rtl_dir/mem/sram_model.v
add_files -norecurse $rtl_dir/bus/apb_regfile_template.v
add_files -norecurse $rtl_dir/bus/ahb2apb_bridge.v
add_files -norecurse $rtl_dir/bus/ahb_matrix.v
add_files -norecurse $rtl_dir/cpu/picorv32.v
add_files -norecurse $rtl_dir/cpu/rv32ec_core.v
add_files -norecurse $rtl_dir/baseband/bb_top.v
add_files -norecurse $rtl_dir/aes/aes_top.v
add_files -norecurse $rtl_dir/eeprom/eep_top.v
add_files -norecurse $rtl_dir/pmu/pmu_top.v
add_files -norecurse $rtl_dir/top/soc_top.v
set_property top soc_top [current_fileset]
update_compile_order -fileset sources_1
puts "\[FLOW\] RTL added: [llength [get_files]] files"

# Add constraints
add_files -fileset constrs_1 -norecurse ../constraints/soc_timing.xdc
add_files -fileset constrs_1 -norecurse ../constraints/soc_pins.xdc
puts "\[FLOW\] Constraints added"

# ================================================================
# 2. Synthesis
# ================================================================
puts "\[FLOW\] Running synthesis..."
set t0 [clock seconds]
synth_design -top soc_top -flatten_hierarchy rebuilt
set t1 [clock seconds]
puts "\[FLOW\] Synthesis done ([expr {$t1-$t0}]s)"

file mkdir $out_dir
report_utilization  -file $out_dir/utilization.rpt
report_timing_summary -file $out_dir/timing.rpt -max_paths 100
report_power         -file $out_dir/power.rpt
puts "\[FLOW\] Synthesis reports saved"

# ================================================================
# 3. Implementation (Place & Route)
# ================================================================
puts "\[FLOW\] Running implementation..."

opt_design
puts "\[FLOW\]   opt_design done"

place_design
puts "\[FLOW\]   place_design done"

phys_opt_design
puts "\[FLOW\]   phys_opt_design done"

route_design
puts "\[FLOW\]   route_design done"

set t2 [clock seconds]
puts "\[FLOW\] Implementation done ([expr {$t2-$t1}]s)"

# ================================================================
# 4. Implementation Reports
# ================================================================
report_timing_summary -file $out_dir/timing_impl.rpt -max_paths 100
report_utilization    -file $out_dir/utilization_impl.rpt
report_power          -file $out_dir/power_impl.rpt
report_clock_networks -file $out_dir/clock_networks_impl.rpt
report_drc            -file $out_dir/drc_impl.rpt
puts "\[FLOW\] Implementation reports saved"

# ================================================================
# 5. Bitstream
# ================================================================
write_bitstream -force $out_dir/soc_top.bit
puts "\[FLOW\] Bitstream: $out_dir/soc_top.bit"

# Summary
set total [expr {$t2-$t0}]
puts "\n\[FLOW\] ===== ALL DONE ====="
puts "\[FLOW\] Total time: [expr {$total/60}]m [expr {$total%60}]s"
puts "\[FLOW\] Bitstream:  $out_dir/soc_top.bit"
puts "\[FLOW\] ======================="
