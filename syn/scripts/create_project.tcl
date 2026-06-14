# ================================================================
# Vivado 工程生成脚本 — 校园智能卡 SoC
# 用法: vivado -mode batch -source create_project.tcl
#       vivado -mode gui  -source create_project.tcl   (GUI)
# ================================================================

# ─── 工程配置 ───
set project_name    "smart_card_soc"
set project_dir     "."
set rtl_dir         "../../rtl"
set sim_dir         "../../sim"
set part            "xc7a35tcsg324-1"      ;# FPGA 原型 (Artix-7)
# set part          "none"                  ;# ASIC 流程

# ─── 清理旧工程 ───
if {[file exists $project_name]} {
    file delete -force $project_name
}

# ═══════════════════════════════════════════════════════════════
# 1. 创建工程
# ═══════════════════════════════════════════════════════════════
create_project -force $project_name $project_dir -part $part
set_property target_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

puts "\[VIVADO\] 工程 $project_name 创建完成 (器件: $part)"

# ═══════════════════════════════════════════════════════════════
# 2. 添加 RTL 设计源 (按编译依赖顺序)
# ═══════════════════════════════════════════════════════════════

# ─── 存储器 ───
add_files -norecurse $rtl_dir/mem/rom_model.v
add_files -norecurse $rtl_dir/mem/sram_model.v

# ─── 总线 ───
add_files -norecurse $rtl_dir/bus/apb_regfile_template.v
add_files -norecurse $rtl_dir/bus/ahb2apb_bridge.v
add_files -norecurse $rtl_dir/bus/ahb_matrix.v

# ─── CPU 行为模型 ───
add_files -norecurse $rtl_dir/cpu/rv32ec_core.v

# ─── APB 外设 ───
add_files -norecurse $rtl_dir/baseband/bb_top.v
add_files -norecurse $rtl_dir/aes/aes_top.v
add_files -norecurse $rtl_dir/eeprom/eep_top.v
add_files -norecurse $rtl_dir/pmu/pmu_top.v

# ─── 顶层 ───
add_files -norecurse $rtl_dir/top/soc_top.v

puts "\[VIVADO\] RTL 源文件: [llength [get_files -of_objects [get_filesets sources_1]]] 个"

# ═══════════════════════════════════════════════════════════════
# 3. 添加仿真源 (sim_1)
# ═══════════════════════════════════════════════════════════════
add_files -fileset sim_1 -norecurse $sim_dir/tb/ahb_master_bfm.v
add_files -fileset sim_1 -norecurse $sim_dir/tb/tb_ahb_bus.v
add_files -fileset sim_1 -norecurse $sim_dir/tb/tb_soc_top.v

set_property top tb_soc_top [get_filesets sim_1]
# set_property top tb_ahb_bus [get_filesets sim_1]  ;# 总线仿真

puts "\[VIVADO\] 仿真顶层 = tb_soc_top"

# ═══════════════════════════════════════════════════════════════
# 4. 顶层 & 编译顺序
# ═══════════════════════════════════════════════════════════════
set_property top soc_top [current_fileset]
update_compile_order -fileset sources_1

# ═══════════════════════════════════════════════════════════════
# 5. 基本时序约束 (13.56 MHz)
# ═══════════════════════════════════════════════════════════════

create_clock -period 73.746 -name clk_sys [get_ports clk_sys]
create_clock -period 73.746 -name rf_clk  [get_ports rf_clk]

set_clock_groups -asynchronous \
    -group [get_clocks clk_sys] \
    -group [get_clocks rf_clk]

set_input_delay  -clock clk_sys -max 5.0 [get_ports {rf_rx sleep test_mode scan_in}]
set_input_delay  -clock clk_sys -min 0.0 [get_ports {rf_rx sleep test_mode scan_in}]
set_output_delay -clock clk_sys -max 5.0 [get_ports {rf_tx scan_out}]
set_output_delay -clock clk_sys -min 0.0 [get_ports {rf_tx scan_out}]

set_false_path -from [get_ports rst_n]

puts "\[VIVADO\] 时序约束已创建 (clk_sys = 13.56 MHz)"

# ═══════════════════════════════════════════════════════════════
# 6. 完成
# ═══════════════════════════════════════════════════════════════
puts "\n\[VIVADO\] ========================================"
puts "\[VIVADO\]  工程生成完成!"
puts "\[VIVADO\]  工程     : $project_name"
puts "\[VIVADO\]  顶层     : soc_top"
puts "\[VIVADO\]  仿真顶层 : tb_soc_top"
puts "\[VIVADO\]  下一步:"
puts "\[VIVADO\]    source synthesis.tcl  (综合)"
puts "\[VIVADO\]    launch_simulation      (仿真)"
puts "\[VIVADO\] ========================================\n"
