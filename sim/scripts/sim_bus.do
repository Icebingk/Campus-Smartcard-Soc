# ================================================================
# ModelSim 仿真脚本 — AHB-Lite + AHB2APB Bridge 单独验证
# 用法: vsim -do sim_bus.do
# ================================================================

# ─── 清理环境 ───
quit -sim

# ─── 创建工作库 ───
vlib work
vmap work work

# ─── 编译源文件 (按依赖顺序) ───
# 总线 RTL
vlog +acc -work work ../../rtl/bus/ahb_matrix.v
vlog +acc -work work ../../rtl/bus/ahb2apb_bridge.v
vlog +acc -work work ../../rtl/bus/apb_regfile_template.v

# 存储器模型 (行为级，仿真用)
vlog +acc -work work ../../rtl/mem/rom_model.v
vlog +acc -work work ../../rtl/mem/sram_model.v

# 简单 CPU 行为模型 (仅用于产生 AHB 读写)
vlog +acc -work work ../../sim/tb/ahb_master_bfm.v

# Testbench
vlog +acc -work work ../../sim/tb/tb_ahb_bus.v

# ─── 加载设计 ───
vsim -t 1ns -voptargs=+acc work.tb_ahb_bus

# ─── 添加波形 ───
add wave -divider "Clock_Reset"
add wave /tb_ahb_bus/clk_sys
add wave /tb_ahb_bus/rst_n

add wave -divider "AHB_Master_BFM"
add wave -radix hex /tb_ahb_bus/cpu_haddr
add wave -radix hex /tb_ahb_bus/cpu_hwdata
add wave -radix hex /tb_ahb_bus/cpu_hrdata
add wave /tb_ahb_bus/cpu_hwrite
add wave /tb_ahb_bus/cpu_htrans
add wave /tb_ahb_bus/cpu_hready
add wave /tb_ahb_bus/cpu_hresp

add wave -divider "AHB_Matrix_Sel"
add wave /tb_ahb_bus/sel_rom
add wave /tb_ahb_bus/sel_sram
add wave /tb_ahb_bus/sel_apb

add wave -divider "APB_Bridge"
add wave -radix hex /tb_ahb_bus/u_bridge/paddr
add wave -radix hex /tb_ahb_bus/u_bridge/pwdata
add wave -radix hex /tb_ahb_bus/u_bridge/prdata
add wave /tb_ahb_bus/u_bridge/psel
add wave /tb_ahb_bus/u_bridge/penable
add wave /tb_ahb_bus/u_bridge/pwrite
add wave /tb_ahb_bus/u_bridge/pready

# ─── 运行仿真 ───
run 10 us

# ─── 退出 ───
quit -f
