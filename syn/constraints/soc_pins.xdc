# ================================================================
# Campus Smartcard SoC — Pin Constraints (XDC)
# Target: Artix-7 xc7a35tcsg324-1 (Nexys A7 / Nexys4 DDR)
# ================================================================

# ================================================================
# Clock (100 MHz onboard osc → use PLL/MMCM to get 13.56 MHz)
# ================================================================
set_property PACKAGE_PIN E3  [get_ports clk_sys]
set_property IOSTANDARD LVCMOS33 [get_ports clk_sys]

# ================================================================
# Reset (active low, push button)
# ================================================================
set_property PACKAGE_PIN C12 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# ================================================================
# RF Interface (PMOD JA)
# ================================================================
set_property PACKAGE_PIN G13 [get_ports rf_rx]
set_property IOSTANDARD LVCMOS33 [get_ports rf_rx]

set_property PACKAGE_PIN B11 [get_ports rf_tx]
set_property IOSTANDARD LVCMOS33 [get_ports rf_tx]

set_property PACKAGE_PIN A11 [get_ports rf_clk]
set_property IOSTANDARD LVCMOS33 [get_ports rf_clk]

# ================================================================
# Sleep (slide switch)
# ================================================================
set_property PACKAGE_PIN J15 [get_ports sleep]
set_property IOSTANDARD LVCMOS33 [get_ports sleep]

# ================================================================
# DFT / Test Interface (PMOD JB)
# ================================================================
set_property PACKAGE_PIN A14 [get_ports test_mode]
set_property IOSTANDARD LVCMOS33 [get_ports test_mode]

set_property PACKAGE_PIN A16 [get_ports scan_clk]
set_property IOSTANDARD LVCMOS33 [get_ports scan_clk]

set_property PACKAGE_PIN B13 [get_ports scan_in]
set_property IOSTANDARD LVCMOS33 [get_ports scan_in]

set_property PACKAGE_PIN A18 [get_ports scan_out]
set_property IOSTANDARD LVCMOS33 [get_ports scan_out]

# ================================================================
# Configuration
# ================================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
