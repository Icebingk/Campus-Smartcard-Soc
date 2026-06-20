# ================================================================
# Campus Smartcard SoC — Timing Constraints (XDC)
# Main clock: 13.56 MHz, period = 73.746 ns
# ================================================================

# --- Main Clock ---
create_clock -period 73.746 -name clk_sys [get_ports clk_sys]

# --- RF Clock (async to main) ---
create_clock -period 73.746 -name rf_clk  [get_ports rf_clk]
set_clock_groups -asynchronous -group [get_clocks clk_sys] -group [get_clocks rf_clk]

# --- Scan Clock ---
create_clock -period 100.000 -name scan_clk [get_ports scan_clk]
set_clock_groups -asynchronous -group [get_clocks clk_sys] -group [get_clocks scan_clk]

# --- Input Delays ---
set_input_delay  -clock clk_sys -max 5.0 [get_ports {rf_rx sleep test_mode scan_in}]
set_input_delay  -clock clk_sys -min 0.0 [get_ports {rf_rx sleep test_mode scan_in}]

# --- Output Delays ---
set_output_delay -clock clk_sys -max 5.0 [get_ports {rf_tx scan_out}]
set_output_delay -clock clk_sys -min 0.0 [get_ports {rf_tx scan_out}]

# --- Async Reset False Path ---
set_false_path -from [get_ports rst_n]

# --- Force distributed RAM for S-Box ROMs (avoid RAMB18 async DRC) ---
set_property rom_style distributed [get_cells -hier -filter {REF_NAME =~ *sbox* || REF_NAME =~ *inv_sbox*}]
set_property ram_style distributed [get_cells -hier -filter {NAME =~ *regfile_reg*}]
