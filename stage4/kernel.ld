ENTRY(kernel_main)

SECTIONS
{
  /* 把内核链接到物理地址 0x1000（与 boot 加载地址一致） */
  . = 0x1000;

  /* 代码段（包含所有 .text*） */
  .text : {
    *(.text*)
  }

  /* 只读数据段 */
  .rodata : {
    *(.rodata*)
  }

  /* 已初始化数据段 */
  .data : {
    *(.data*)
  }

  /* 未初始化数据段和 COMMON 符号 */
  .bss : {
    *(.bss*)
    *(COMMON)
  }
}

