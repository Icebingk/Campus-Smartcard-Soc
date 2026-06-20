source ../scripts/synopsys_dc.setup
set_svf ../output_data/hdmi_encoder.svf

analyze -library WORK -format verilog {../rtl/MY_DESIGN.v}
elaborate MY_DESIGN -architecture verilog -library DEFAULT

link
check_design

source ../scripts/top_constraints.tcl

check_timing
report_clock
report_clock -skew
report_port -verbose

write_script -out ../scripts/HDMI_ENCODER.wscr

write -format ddc -hier -out ../output_data/HDMI_ENCODER.unmapped.ddc

compile_ultra -no_autoungroup -scan

report_timing > ../rpt/timing.rpt
report_power > ../rpt/power.rpt
report_area > ../rpt/area.rpt
report_constraint -all_violators > ../rpt/all_viosl.rpt

#--------------------------


#-------------------------
set_svf -off

define_name_rules verilog -case_insensitive \
    -allowed "A-Z a-z 0-9 _" \
    -first_restricted "0-9_" \
    -last_restricted "_" \
    -replacement_char "_" \
    -equal_ports_nets

change_names -rules verilog -hierarchy

write_sdc ../output_data/MY_DESIGN.sdc
write -format ddc -hierarchy -output ../output_data/MY_DESIGN.mapped.ddc
write -format verilog -hier -out ../output_data/MY_DESIGN.mapped.v



