set_svf STOTO.svf

read_verilog STOTO.v

current_design STOTO

link
check_design

source STOTO.con
check_timing

source STOTO.pcon

report_clock
group_path -name clk -critical 0.21 -weight 5
group_path -name INPUTS -from [all_inputs] 
group_path -name OUTPUTS -to [all_output]
group_path -name COMBO -from [all_inputs] -to [all_output]

set_ungroup [get_designs "INPUT"] false

set_optimize_registers true -design PIPELINE

set_dont_retime [get_cells I_MIDDLE/I_PIPELINE/z_reg*] true

set_dont_retime [get_cells I_MIDDLE/I_DONT_PIPELINE] true

set_cost_priority -delay

report_path_group
get_attribute [get_designs "INPUT"] ungroup
get_attribute [get_designs "PIPELINE"]  optimize_registers
get_attribute [get_cells I_MIDDLE/I_PIPELINE/z_reg*] dont_retime
get_attribute [get_cells I_MIDDLE/I_DONT_PIPELINE] dont_retime
get_attribute [get_designs "STOTO"] cost_priority

write -f ddc -hier -out unmapped/STOTO.ddc

set_host_options -max_cores 4
report_host_options

compile_ultra -spg -retime -scan 

list_licenses

report_hierarchy -noleaf

redirect -tee -file rc_compile_ultra.rpt {report_constraint -all}

printvar register_replication_naming_style
filter_collection [all_registers] "full_name =~ *_rep*"

redirect -tee -file rt_compile_ultra.rpt {report_timing}

write -f ddc -hier -out mapped/STOTO.ddc

set_svf -off

get_cells -hier *r_REG*_S*

report_cell -nosplit I_MIDDLE/I_PIPELINE

get_cells -hier *z_reg*

report_timing -from I_MIDDLE/I_PIPELINE/z_reg*/*

get_cells -hier R_*

report_cell -nosplit I_IN

get_cells  I_IN/*_reg* 

set_cost_priority -default
compile_ultra -spg -retime -scan -incremental

redirect -tee -file rc_incr_compile.rpt {rc}

report_physical_constraints

exit
