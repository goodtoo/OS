ENTRY(kernel_main)

SECTIONS
{
    /* 内核从物理地址 0x1000（4KB）处加载 */
    . = 0x1000;

    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss COMMON)
    }
}
