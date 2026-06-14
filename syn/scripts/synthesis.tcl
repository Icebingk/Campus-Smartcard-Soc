# ================================================================
# Vivado 综合脚本 — 校园智能卡 SoC
# 前提: 已运行 create_project.tcl 创建工程
# 用法: vivado -mode batch -source create_project.tcl -source synthesis.tcl
#       vivado -mode batch -source synthesis.tcl   (若工程已存在)
# ================================================================

set out_dir  "../outputs"

# ─── 打开工程 (若不存在则创建) ───
if {[get_projects -quiet] eq ""} {
    puts "\[SYN\] 工程未打开, 请先运行 create_project.tcl"
    # 也可在此直接创建, 取消注释:
    # source create_project.tcl
}

# ═══════════════════════════════════════════════════════════════
# 1. 综合选项
# ═══════════════════════════════════════════════════════════════
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION       auto    [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS 1 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING      auto    [get_runs synth_1]

puts "\[SYN\] 综合选项已配置"
puts "\[SYN\]   展平层级  : rebuilt"
puts "\[SYN\]   资源共享  : auto"
puts "\[SYN\]   保留等价寄存器: on"

# ═══════════════════════════════════════════════════════════════
# 2. 运行综合
# ═══════════════════════════════════════════════════════════════
puts "\[SYN\] 开始综合..."
set start_time [clock seconds]

synth_design -top soc_top -flatten_hierarchy rebuilt -verbose

set elapsed [expr {[clock seconds] - $start_time}]
puts "\[SYN\] 综合完成 (耗时 [expr {$elapsed / 60}] 分 [expr {$elapsed % 60}] 秒)"

# ═══════════════════════════════════════════════════════════════
# 3. 生成报告
# ═══════════════════════════════════════════════════════════════
file mkdir $out_dir

# 资源利用率
report_utilization -file $out_dir/utilization.rpt
puts "\[SYN\] -> $out_dir/utilization.rpt"

# 时序摘要 (最大 100 条路径)
report_timing_summary -file $out_dir/timing.rpt -max_paths 100
puts "\[SYN\] -> $out_dir/timing.rpt"

# 功耗估算
report_power -file $out_dir/power.rpt
puts "\[SYN\] -> $out_dir/power.rpt"

# 时钟网络
report_clock_networks -file $out_dir/clock_networks.rpt
puts "\[SYN\] -> $out_dir/clock_networks.rpt"

# 设计规则检查
report_drc -file $out_dir/drc.rpt
puts "\[SYN\] -> $out_dir/drc.rpt"

# ═══════════════════════════════════════════════════════════════
# 4. 导出网表
# ═══════════════════════════════════════════════════════════════
write_verilog -force $out_dir/soc_synth_netlist.v
puts "\[SYN\] -> $out_dir/soc_synth_netlist.v"

# EDIF 格式 (工业标准, 供后端工具)
# write_edif -force $out_dir/soc_synth.edf

# ═══════════════════════════════════════════════════════════════
# 5. 关键指标摘要
# ═══════════════════════════════════════════════════════════════
puts "\n\[SYN\] ========================================"
puts "\[SYN\]  综合完成!"
puts "\[SYN\]  输出目录 : $out_dir/"
puts "\[SYN\]  报告文件 :"
puts "\[SYN\]    利用率 : utilization.rpt"
puts "\[SYN\]    时序   : timing.rpt"
puts "\[SYN\]    功耗   : power.rpt"
puts "\[SYN\]    DRC    : drc.rpt"
puts "\[SYN\]    网表   : soc_synth_netlist.v"
puts "\[SYN\] ========================================\n"
