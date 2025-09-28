; kernel/start.asm — 固定的 32-bit 内核入口，确保位于 0x1000
[BITS 32]
GLOBAL kernel_entry
EXTERN kernel_main

SECTION .text.start
kernel_entry:
    ; 可选：给出一个明显标记
    mov word [0xB8000 + 80*4*2 + 0], 0x0F45    ; 'E'
    mov word [0xB8000 + 80*4*2 + 2], 0x0F4E    ; 'N'
    mov word [0xB8000 + 80*4*2 + 4], 0x0F54    ; 'T'  => 在第5行开头显示 "ENT"

    call kernel_main

.hang:
    hlt
    jmp .hang
