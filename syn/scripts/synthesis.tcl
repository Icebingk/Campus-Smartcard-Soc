# ================================================================
# Vivado Synthesis — Campus Smartcard SoC
# Prerequisite: run create_project.tcl first
# Usage: vivado -mode batch -source create_project.tcl -source synthesis.tcl
# ================================================================

set out_dir  "../outputs"

# --- Open Project ---
if {[get_projects -quiet] eq ""} {
    puts "\[SYN\] Project not open. Run create_project.tcl first."
}

# ================================================================
# 1. Synthesis Options
# ================================================================
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION       auto    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS 1 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING      auto    [get_runs synth_1]

puts "\[SYN\] Options: flatten=rebuilt share=auto keep_eq=on"

# ================================================================
# 2. Run Synthesis
# ================================================================
puts "\[SYN\] Running synthesis..."
set start_time [clock seconds]

synth_design -top soc_top -flatten_hierarchy rebuilt -verbose

set elapsed [expr {[clock seconds] - $start_time}]
puts "\[SYN\] Done ([expr {$elapsed / 60}]m [expr {$elapsed % 60}]s)"

# ================================================================
# 3. Reports
# ================================================================
file mkdir $out_dir

report_utilization -file $out_dir/utilization.rpt
puts "\[SYN\] -> utilization.rpt"

report_timing_summary -file $out_dir/timing.rpt -max_paths 100
puts "\[SYN\] -> timing.rpt"

report_power -file $out_dir/power.rpt
puts "\[SYN\] -> power.rpt"

report_clock_networks -file $out_dir/clock_networks.rpt
puts "\[SYN\] -> clock_networks.rpt"

report_drc -file $out_dir/drc.rpt
puts "\[SYN\] -> drc.rpt"

# ================================================================
# 4. Export Netlist
# ================================================================
write_verilog -force $out_dir/soc_synth_netlist.v
puts "\[SYN\] -> soc_synth_netlist.v"

# ================================================================
# 5. Done
# ================================================================
puts "\n\[SYN\] ========================================"
puts "\[SYN\]  Synthesis Complete!"
puts "\[SYN\]  Outputs: $out_dir/"
puts "\[SYN\] ========================================\n"
