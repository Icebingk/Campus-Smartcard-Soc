# ================================================================
# Vivado Synthesis 脚本 — 校园智能卡 SoC 全芯片综合
# 用法: vivado -mode batch -source synthesis.tcl
# ================================================================

# ─── 项目设置 ───
set project_name  smart_card_soc
set project_dir   .
set rtl_dir       ../../rtl
set out_dir       ./outputs

# ─── 创建项目 ───
create_project -force $project_name $project_dir -part xc7a35tcsg324-1
# 注: 若使用 ASIC 标准单元库，请替换为 target_library 方式

# ─── 添加 RTL 源文件 ───
set_property source_mgmt_mode All [current_project]

# 存储器
add_files -norecurse $rtl_dir/mem/rom_model.v
add_files -norecurse $rtl_dir/mem/sram_model.v

# 总线
add_files -norecurse $rtl_dir/bus/apb_regfile_template.v
add_files -norecurse $rtl_dir/bus/ahb2apb_bridge.v
add_files -norecurse $rtl_dir/bus/ahb_matrix.v

# CPU
add_files -norecurse $rtl_dir/cpu/rv32ec_core.v

# 外设
add_files -norecurse $rtl_dir/baseband/bb_top.v
add_files -norecurse $rtl_dir/aes/aes_top.v
add_files -norecurse $rtl_dir/eeprom/eep_top.v
add_files -norecurse $rtl_dir/pmu/pmu_top.v

# 顶层
add_files -norecurse $rtl_dir/top/soc_top.v

# ─── 设置顶层模块 ───
set_property top soc_top [current_fileset]
update_compile_order -fileset sources_1

# ─── 读入 SDC 约束（与陆凤敏协作）───
# read_xdc ../../constraints/soc_timing.sdc

# ─── 基本约束示例 ───
create_clock -name clk_sys -period 73.746 [get_ports clk_sys]
# 13.56 MHz -> 周期约 73.746 ns
# 如果是分频时钟，请根据实际规格调整

set_input_delay -clock clk_sys -max 5.0 [get_ports {rf_rx sleep}]
set_input_delay -clock clk_sys -min 1.0 [get_ports {rf_rx sleep}]
set_output_delay -clock clk_sys -max 5.0 [get_ports rf_tx]
set_output_delay -clock clk_sys -min 1.0 [get_ports rf_tx]

# ─── 运行综合 ───
synth_design -top soc_top -flatten_hierarchy rebuilt

# ─── 生成报告 ───
file mkdir $out_dir
report_utilization   -file $out_dir/utilization.rpt
report_timing_summary -file $out_dir/timing.rpt -max_paths 100
report_power         -file $out_dir/power.rpt

# ─── 导出网表 ───
write_verilog -force $out_dir/soc_synth_netlist.v
# write_edif $out_dir/soc_synth.edf   # 工业标准网表格式

puts "=========================================="
puts " Synthesis completed! Check $out_dir/"
puts "=========================================="
