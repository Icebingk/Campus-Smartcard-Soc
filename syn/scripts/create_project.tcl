# ================================================================
# Vivado Project Creation — Campus Smartcard SoC
# Usage: vivado -mode batch -source create_project.tcl
#        vivado -mode gui  -source create_project.tcl   (GUI)
# ================================================================

# --- Project Config ---
set project_name    "smart_card_soc"
set project_dir     "../vivado"
set rtl_dir         "../../rtl"
set sim_dir         "../../sim"
set part            "xc7a35tcsg324-1"      ;# FPGA prototype (Artix-7)
# set part          "none"                  ;# ASIC flow

# --- Cleanup ---
if {[file exists $project_dir/$project_name]} {
    file delete -force $project_dir/$project_name
}

# ================================================================
# 1. Create Project
# ================================================================
create_project -force $project_name $project_dir -part $part
set_property target_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

puts "\[VIVADO\] Project $project_name created (part: $part)"

# ================================================================
# 2. Add RTL Sources (dependency order)
# ================================================================

# --- Memory ---
add_files -norecurse $rtl_dir/mem/rom_model.v
add_files -norecurse $rtl_dir/mem/sram_model.v

# --- Bus ---
add_files -norecurse $rtl_dir/bus/apb_regfile_template.v
add_files -norecurse $rtl_dir/bus/ahb2apb_bridge.v
add_files -norecurse $rtl_dir/bus/ahb_matrix.v

# --- CPU (Open-Source PicoRV32 RV32EC + AHB Wrapper) ---
add_files -norecurse $rtl_dir/cpu/picorv32.v
add_files -norecurse $rtl_dir/cpu/rv32ec_core.v

# --- APB Peripherals ---
add_files -norecurse $rtl_dir/baseband/bb_top.v
add_files -norecurse $rtl_dir/aes/aes_top.v
add_files -norecurse $rtl_dir/eeprom/eep_top.v
add_files -norecurse $rtl_dir/pmu/pmu_top.v

# --- Top-Level ---
add_files -norecurse $rtl_dir/top/soc_top.v

puts "\[VIVADO\] RTL sources: [llength [get_files -of_objects [get_filesets sources_1]]] files"

# ================================================================
# 3. Add Simulation Sources (sim_1)
# ================================================================
add_files -fileset sim_1 -norecurse $sim_dir/tb/ahb_master_bfm.v
add_files -fileset sim_1 -norecurse $sim_dir/tb/tb_ahb_bus.v
add_files -fileset sim_1 -norecurse $sim_dir/tb/tb_soc_top.v

set_property top tb_soc_top [get_filesets sim_1]
# set_property top tb_ahb_bus [get_filesets sim_1]  ;# bus-only sim

puts "\[VIVADO\] Sim top = tb_soc_top"

# ================================================================
# 4. Set Top & Compile Order
# ================================================================
set_property top soc_top [current_fileset]
update_compile_order -fileset sources_1

# ================================================================
# 5. Add Timing Constraints (XDC)
# ================================================================

add_files -fileset constrs_1 -norecurse ../constraints/soc_timing.xdc
add_files -fileset constrs_1 -norecurse ../constraints/soc_pins.xdc
puts "\[VIVADO\] Constraints: soc_timing.xdc + soc_pins.xdc"

# ================================================================
# 6. Done
# ================================================================
puts "\n\[VIVADO\] ========================================"
puts "\[VIVADO\]  Project ready!"
puts "\[VIVADO\]  Project  : $project_name"
puts "\[VIVADO\]  Top      : soc_top"
puts "\[VIVADO\]  Sim Top  : tb_soc_top"
puts "\[VIVADO\]  Next:"
puts "\[VIVADO\]    source synthesis.tcl  (run synthesis)"
puts "\[VIVADO\]    launch_simulation      (run simulation)"
puts "\[VIVADO\] ========================================\n"
