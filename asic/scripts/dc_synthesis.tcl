# ================================================================
# DC Synthesis — Campus Smartcard SoC (TSMC 90nm)
# Usage: dc_shell -f dc_synthesis.tcl | tee ../reports/dc_synthesis.log
# ================================================================

# ─── 1. Read RTL ───
set RTL "../../rtl"

analyze -library WORK -format verilog [list \
    $RTL/mem/rom_model.v       \
    $RTL/mem/sram_model.v      \
    $RTL/cpu/picorv32.v        \
    $RTL/cpu/rv32ec_core.v    \
    $RTL/bus/ahb2apb_bridge.v \
    $RTL/bus/ahb_matrix.v     \
    $RTL/bus/apb_regfile_template.v \
    $RTL/baseband/bb_top.v    \
    $RTL/aes/aes_top.v        \
    $RTL/eeprom/eep_top.v     \
    $RTL/pmu/pmu_top.v        \
    $RTL/top/soc_top.v        \
]

elaborate soc_top
current_design soc_top
link
check_design

# ─── 2. Constraints ───
set clk_period 73.746
create_clock -name clk_sys -period $clk_period [get_ports clk_sys]
set_clock_uncertainty 0.5 [get_clocks clk_sys]
set_dont_touch_network [get_clocks clk_sys]

set_false_path -from [get_ports rst_n]

set_input_delay  5.0 -clock clk_sys [remove_from_collection [all_inputs] [get_ports {clk_sys rst_n rf_clk scan_clk}]]
set_output_delay 5.0 -clock clk_sys [all_outputs]
set_driving_cell -lib_cell BUFX2 [all_inputs]
set_load 0.05 [all_outputs]
set_max_area 0

check_timing

# ─── 3. Compile ───
compile_ultra -no_autoungroup

# ─── 4. Reports ───
file mkdir ../reports
report_timing   > ../reports/dc_timing.rpt
report_area     > ../reports/dc_area.rpt
report_power    > ../reports/dc_power.rpt
report_cell     > ../reports/dc_cell.rpt
report_qor      > ../reports/dc_qor.rpt
report_constraint -all_violators > ../reports/dc_violations.rpt

# ─── 5. Output ───
file mkdir ../outputs
define_name_rules verilog -case_insensitive \
    -allowed "A-Z a-z 0-9 _" -first_restricted "0-9_" \
    -last_restricted "_" -replacement_char "_" -equal_ports_nets
change_names -rules verilog -hierarchy
write -format verilog -hier -out ../outputs/soc_top_netlist.v
write_sdc ../outputs/soc_top.sdc
write_sdf -version 2.1 ../outputs/soc_top.sdf

puts "\[DC\] ===== Synthesis Complete ====="
exit
