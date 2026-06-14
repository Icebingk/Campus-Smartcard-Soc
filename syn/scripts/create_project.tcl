# ================================================================
# Vivado 项目创建脚本
# 用法: vivado -mode batch -source create_project.tcl
# ================================================================

set project_name "smart_card_soc"
set project_dir  "."
set rtl_dir      "../rtl"

# 清理旧工程
if {[file exists $project_name]} {
    file delete -force $project_name
}

# ================================================================
# 创建项目
# ================================================================
create_project -force $project_name $project_dir -part xc7a35tcsg324-1
set_property target_language Verilog [current_project]

# ================================================================
# 添加 RTL 源文件 (按依赖顺序)
# ================================================================

# 存储器
add_files -norecurse "$rtl_dir/mem/rom_model.v"
add_files -norecurse "$rtl_dir/mem/sram_model.v"

# 总线与桥接
add_files -norecurse "$rtl_dir/bus/apb_regfile_template.v"
add_files -norecurse "$rtl_dir/bus/ahb_matrix.v"
add_files -norecurse "$rtl_dir/bus/ahb2apb_bridge.v"

# CPU 核 (后续添加)
# add_files -norecurse "$rtl_dir/cpu/rv32ec_core.v"

# 外设模块 (待编写)
# add_files -norecurse "$rtl_dir/baseband/bb_top.v"
# add_files -norecurse "$rtl_dir/aes/aes_top.v"
# add_files -norecurse "$rtl_dir/eeprom/eep_top.v"
# add_files -norecurse "$rtl_dir/pmu/pmu_top.v"

# 顶层 (待编写)
# add_files -norecurse "$rtl_dir/top/soc_top.v"

# ================================================================
# 添加仿真源文件
# ================================================================

add_files -fileset sim_1 -norecurse "../sim/tb/ahb_master_bfm.v"
add_files -fileset sim_1 -norecurse "../sim/tb/tb_ahb_bus.v"

# ================================================================
# 设置顶层模块
# ================================================================

# 暂时设为 Testbench
set_property top tb_ahb_bus [get_filesets sim_1]

puts "=========================================="
puts " Project created: $project_name"
puts " Target device: xc7a35tcsg324-1"
puts " RTL files added:"
puts "   - Memory models (ROM/SRAM)"
puts "   - Bus Matrix & AHB2APB Bridge"
puts "   - Simulation testbench"
puts ""
puts " Next steps:"
puts "   1. Add RTL for CPU, Baseband, AES, etc."
puts "   2. Set soc_top as implementation top level"
puts "   3. Run Synthesis/Implementation"
puts "=========================================="

# 保存工程
save_project_as -force -file ./$project_name/$project_name.xpr

puts "Project saved to $project_name/$project_name.xpr"
