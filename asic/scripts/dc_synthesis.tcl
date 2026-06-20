# ================================================================
# Synopsys Design Compiler — Campus Smartcard SoC
# Target: TSMC 90nm (tcbn90g)  slow corner  @13.56MHz
# Usage: dc_shell -f dc_synthesis.tcl | tee ../reports/dc_synthesis.log
# ================================================================

# ================================================================
# 0. Library Setup — TSMC 90nm
# ================================================================
set TSMC90    "/opt/Foundary_Library/TSMC90/aci/sc-x/synopsys"
set search_path [list . $TSMC90]
set target_library   "slow.db"
set link_library     "* slow.db"

suppress_message "UID-401"
suppress_message "LNK-041"

# ================================================================
# 1. Read RTL Design
# ================================================================
set RTL_DIR "../../rtl"

# CPU
analyze -format verilog $RTL_DIR/cpu/picorv32.v
analyze -format verilog $RTL_DIR/cpu/rv32ec_core.v

# Bus
analyze -format verilog $RTL_DIR/bus/ahb2apb_bridge.v
analyze -format verilog $RTL_DIR/bus/ahb_matrix.v
analyze -format verilog $RTL_DIR/bus/apb_regfile_template.v

# Peripherals
analyze -format verilog $RTL_DIR/baseband/bb_top.v
analyze -format verilog $RTL_DIR/aes/aes_top.v
analyze -format verilog $RTL_DIR/eeprom/eep_top.v
analyze -format verilog $RTL_DIR/pmu/pmu_top.v

# Top
analyze -format verilog $RTL_DIR/top/soc_top.v

# ROM/SRAM: 行为模型不参与综合，在 ICC2 中用硬核替换
# analyze -format verilog $RTL_DIR/mem/rom_model.v
# analyze -format verilog $RTL_DIR/mem/sram_model.v

elaborate soc_top
current_design soc_top

# ================================================================
# 2. Design Constraints
# ================================================================

set clk_period      73.746   ;# 13.56 MHz
set clk_uncertainty 0.5
set input_delay     5.0
set output_delay    5.0

# Clock
create_clock -name clk_sys -period $clk_period [get_ports clk_sys]
set_clock_uncertainty $clk_uncertainty [get_clocks clk_sys]
set_dont_touch_network [get_clocks clk_sys]

# Reset
set_false_path -from [get_ports rst_n]

# Async clocks
create_clock -name rf_clk  -period $clk_period [get_ports rf_clk]
create_clock -name scan_clk -period 100.0      [get_ports scan_clk]
set_clock_groups -asynchronous \
    -group [get_clocks clk_sys] \
    -group [get_clocks rf_clk] \
    -group [get_clocks scan_clk]

# I/O delays
set_input_delay  $input_delay  -clock clk_sys [remove_from_collection [all_inputs] [get_ports {clk_sys rst_n rf_clk scan_clk}]]
set_output_delay $output_delay -clock clk_sys [all_outputs]

# Drive and load
set_driving_cell -lib_cell BUFX2 [all_inputs]
set_load 0.05 [all_outputs]

# Minimize area
set_max_area 0

# ================================================================
# 3. Compile (Synthesis)
# ================================================================
compile_ultra -gate_clock -no_autoungroup

# ================================================================
# 4. Reports
# ================================================================
file mkdir ../reports

report_area   > ../reports/dc_area.rpt
report_timing > ../reports/dc_timing.rpt
report_power  > ../reports/dc_power.rpt
report_cell   > ../reports/dc_cell.rpt
report_qor    > ../reports/dc_qor.rpt

# ================================================================
# 5. Output Netlist & Constraints
# ================================================================
change_names -hierarchy -rules verilog
write -format verilog -hierarchy -output ../outputs/soc_top_netlist.v
write_sdf -version 2.1 ../outputs/soc_top.sdf
write_sdc ../outputs/soc_top.sdc

puts "\[DC\] ========================================"
puts "\[DC\]  Synthesis Complete"
puts "\[DC\]  Reports:  ../reports/"
puts "\[DC\]  Netlist:  ../outputs/soc_top_netlist.v"
puts "\[DC\] ========================================"
exit
