ENTRY(kernel_entry)

SECTIONS
{
  . = 0x1000;

  _kernel_start = .;

  .text.start : { *(.text.start*) }    /* 固定入口段，最先放 */
  .text       : { *(.text*) }
  .rodata     : { *(.rodata*) }
  .data       : { *(.data*) }
  .bss        : { *(.bss*) *(COMMON) }

  _kernel_end = .;
}

