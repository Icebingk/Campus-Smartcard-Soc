# ============================================================================
# 固件 Makefile — 校园智能卡 SoC
# ============================================================================
# Prerequisites: riscv-none-elf-gcc (xPack RISC-V Embedded GCC)
# Usage:
#   make -f firmware.mk          # 编译生成 firmware.hex
#   make -f firmware.mk clean    # 清理
# ============================================================================

TOOLCHAIN ?= riscv-none-elf-
CC        = $(TOOLCHAIN)gcc
OBJCOPY   = $(TOOLCHAIN)objcopy
OBJDUMP   = $(TOOLCHAIN)objdump
SIZE      = $(TOOLCHAIN)size

# ─── 编译选项 ───
# -march=rv32ec: RV32E + Compressed
# -mabi=ilp32e: 嵌入式整数 ABI (16 regs)
ARCH      = rv32ec
ABI       = ilp32e

CFLAGS    = -march=$(ARCH) -mabi=$(ABI) \
            -Os -nostdlib -nostartfiles -ffreestanding \
            -Wall -Wno-unused -fno-builtin \
            -fno-delete-null-pointer-checks \
            -T linker.ld

LDFLAGS   = -march=$(ARCH) -mabi=$(ABI) \
            -nostdlib -nostartfiles -ffreestanding \
            -T linker.ld -Wl,-Map,firmware.map

# ─── 源文件 ───
OBJS     = startup.o main.o
TARGET   = firmware
HEX      = $(TARGET).hex
ELF      = $(TARGET).elf
MAP      = $(TARGET).map
LST      = $(TARGET).lst

# ─── 默认目标 ───
.PHONY: all clean dump

all: $(HEX)

# ─── 编译 ───
%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $@
	$(SIZE) $@

# ─── 生成 Verilog $readmemh 可读的 hex 文件 ───
$(HEX): $(ELF)
	$(OBJCOPY) -O verilog $< $@

# ─── 反汇编查看 ───
$(LST): $(ELF)
	$(OBJDUMP) -d $< > $@

dump: $(LST)
	@cat $(LST)

# ─── 清理 ───
clean:
	rm -f *.o $(ELF) $(HEX) $(MAP) $(LST)
