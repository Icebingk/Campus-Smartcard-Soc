/* ============================================================================
 * 链接脚本 — 校园智能卡 SoC (PicoRV32 RV32EC)
 * ============================================================================
 * ROM:  0x00000000  16KB  (代码 + 只读数据)
 * SRAM: 0x00010000  8KB   (数据 + BSS + 栈)
 * 栈顶: SRAM 末尾 - 4 = 0x00011FFC
 *
 * 用法: riscv-none-elf-gcc -T linker.ld ...
 * ============================================================================ */

MEMORY
{
    ROM  (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    SRAM (rw)  : ORIGIN = 0x00010000, LENGTH = 8K
}

SECTIONS
{
    /* ─── 代码段 (ROM) ─── */
    .text : {
        *(.text.start)          /* startup.s 放在最前面 */
        *(.text .text.*)
        *(.rodata .rodata.*)
    } > ROM

    /* ─── 数据段 (SRAM) ─── */
    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data .data.*)
        . = ALIGN(4);
        _edata = .;
    } > SRAM AT > ROM

    /* ─── BSS 段 (SRAM, 不占 ROM 空间) ─── */
    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > SRAM

    /* ─── 栈 (SRAM 顶部) ─── */
    .stack (NOLOAD) : {
        . = ALIGN(4);
        . = ORIGIN(SRAM) + LENGTH(SRAM) - 4;
        _estack = .;
    } > SRAM
}
