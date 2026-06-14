# ================================================================
# 校园智能卡 SoC — 时序约束 (XDC)
# 主时钟: 13.56 MHz, 周期 ≈ 73.746 ns
# ================================================================

# ─── 主时钟 ───
create_clock -period 73.746 -name clk_sys [get_ports clk_sys]

# ─── 射频时钟 (同频异步) ───
create_clock -period 73.746 -name rf_clk  [get_ports rf_clk]
set_clock_groups -asynchronous -group [get_clocks clk_sys] -group [get_clocks rf_clk]

# ─── 扫描时钟 ───
create_clock -period 100.000 -name scan_clk [get_ports scan_clk]
set_clock_groups -asynchronous -group [get_clocks clk_sys] -group [get_clocks scan_clk]

# ─── 输入延迟 ───
set_input_delay  -clock clk_sys -max 5.0 [get_ports {rf_rx sleep test_mode scan_in}]
set_input_delay  -clock clk_sys -min 0.0 [get_ports {rf_rx sleep test_mode scan_in}]

# ─── 输出延迟 ───
set_output_delay -clock clk_sys -max 5.0 [get_ports {rf_tx scan_out}]
set_output_delay -clock clk_sys -min 0.0 [get_ports {rf_tx scan_out}]

# ─── 异步复位 false path ───
set_false_path -from [get_ports rst_n]
