# ================================================================
# ModelSim 仿真脚本 — 全芯片顶层仿真
# 用法: vsim -do sim_top.do
# ================================================================

# ─── 清理环境 ───
quit -sim

# ─── 创建工作库 ───
vlib work
vmap work work

# ─── RTL 文件列表（按依赖顺序编译）───
set RTL_DIR ../../rtl

# 基础组件
vlog +acc -work work $RTL_DIR/mem/rom_model.v
vlog +acc -work work $RTL_DIR/mem/sram_model.v
vlog +acc -work work $RTL_DIR/bus/apb_regfile_template.v

# 总线
vlog +acc -work work $RTL_DIR/bus/ahb2apb_bridge.v
vlog +acc -work work $RTL_DIR/bus/ahb_matrix.v

# CPU (PicoRV32 + AHB Wrapper — real firmware execution)
vlog +acc -work work $RTL_DIR/cpu/picorv32.v
vlog +acc -work work $RTL_DIR/cpu/rv32ec_core.v

# 外设模块
vlog +acc -work work $RTL_DIR/baseband/bb_top.v
vlog +acc -work work $RTL_DIR/aes/aes_top.v
vlog +acc -work work $RTL_DIR/eeprom/eep_top.v
vlog +acc -work work $RTL_DIR/pmu/pmu_top.v

# 顶层
vlog +acc -work work $RTL_DIR/top/soc_top.v

# Testbench
vlog +acc -work work ../tb/tb_soc_top.v

# ─── 加载顶层 ───
vsim -t 1ns -voptargs=+acc work.tb_soc_top

# ─── 忽略波形添加时的错误，继续执行 ───
onerror {resume}

# ─── 添加关键波形 ───
add wave -divider "Clock & Reset"
add wave /tb_soc_top/clk_sys
add wave /tb_soc_top/rst_n

add wave -divider "CPU AHB"
add wave -radix hex /tb_soc_top/uut/cpu_haddr
add wave -radix hex /tb_soc_top/uut/cpu_hrdata
add wave /tb_soc_top/uut/cpu_hwrite

add wave -divider "Interrupts"
add wave /tb_soc_top/uut/irq_bb
add wave /tb_soc_top/uut/irq_aes
add wave /tb_soc_top/uut/irq_eep

add wave -divider "Baseband Registers"
add wave -radix hex /tb_soc_top/uut/u_baseband/paddr
add wave -radix hex /tb_soc_top/uut/u_baseband/pwdata
add wave -radix hex /tb_soc_top/uut/u_baseband/prdata

add wave -divider "AES Registers"
add wave -radix hex /tb_soc_top/uut/u_aes/paddr
add wave -radix hex /tb_soc_top/uut/u_aes/pwdata
add wave -radix hex /tb_soc_top/uut/u_aes/prdata

# ─── 运行仿真 ───
run -all

# ─── 查看波形 ───
wave zoom full
