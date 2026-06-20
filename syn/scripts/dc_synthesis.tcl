# ================================================================
# Synopsys Design Compiler — Campus Smartcard SoC
# ================================================================
# Usage: dc_shell -f dc_synthesis.tcl | tee dc_synthesis.log
# ================================================================

# ================================================================
# 0. Library Setup (根据 VM 上的路径修改)
# ================================================================
# 示例 (TSMC 65nm):
# set search_path [list . /opt/TSMC65/../synopsys /opt/TSMC65/../db]
# set target_library   "tcbn65gpluswc.db"
# set link_library     "* $target_library tcbn65gpluswc.db"
# set synthetic_library "dw_foundation.sldb"

# TODO: 替换为你 VM 上实际的库路径
set LIB_PATH "/path/to/your/technology/lib"
set search_path [list . $LIB_PATH]
# set target_library "your_std_cell_ss.db"    ;# slow corner
# set link_library   "* $target_library"
# set symbol_library "your_std_cell.sdb"

# ================================================================
# 1. Read RTL Design
# ================================================================
set RTL_DIR "../../rtl"

# Memory (Behavioral — replace with SRAM hard macro for ASIC)
# analyze -format verilog $RTL_DIR/mem/rom_model.v
# analyze -format verilog $RTL_DIR/mem/sram_model.v

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

# Don't touch ROM/SRAM behavioral models during synthesis
# set_dont_touch [get_cells -hier "u_rom"]
# set_dont_touch [get_cells -hier "u_sram"]

elaborate soc_top
current_design soc_top

# ================================================================
# 2. Design Constraints
# ================================================================

# ─── Clock ───
set clk_period    73.746    ;# 13.56 MHz
set clk_skew      0.5
set clk_trans     0.3
set clk_uncertainty 0.2
set input_delay   5.0
set output_delay  5.0

create_clock -name clk_sys -period $clk_period [get_ports clk_sys]
set_clock_uncertainty $clk_uncertainty [get_clocks clk_sys]

# Reset
set_false_path -from [get_ports rst_n]

# Input delays
set_input_delay  $input_delay -clock clk_sys [remove_from_collection [all_inputs] [get_ports {clk_sys rst_n}]]
set_output_delay $output_delay -clock clk_sys [all_outputs]

# Max area (set to 0 = minimize)
set_max_area 0

# ================================================================
# 3. Compile (Synthesis)
# ================================================================
compile_ultra -gate_clock -no_autoungroup

# ================================================================
# 4. Reports
# ================================================================
report_area   >  ../outputs/dc_area.rpt
report_timing >  ../outputs/dc_timing.rpt
report_power  >  ../outputs/dc_power.rpt
report_cell   >  ../outputs/dc_cell.rpt
report_qor    >  ../outputs/dc_qor.rpt

# ================================================================
# 5. Output Netlist
# ================================================================
# Change names to verilog-friendly
change_names -hierarchy -rules verilog
write -format verilog -hierarchy -output ../outputs/soc_top_netlist.v
write_sdf -version 2.1 ../outputs/soc_top.sdf
write_sdc ../outputs/soc_top.sdc

puts "\[DC\] ===== Synthesis Complete ====="
exit
