[BITS 32]
GLOBAL isr0
GLOBAL irq0
GLOBAL irq1

extern isr_handler

section .text

isr0:
    cli
    pusha
    mov eax, 0
    push eax
    call isr_handler
    add esp, 4
    popa
    sti
    iret

irq0:
    cli
    pusha
    mov eax, 32
    push eax
    call isr_handler
    add esp, 4
    popa
    sti
    iret

irq1:
    cli
    pusha
    mov eax, 33
    push eax
    call isr_handler
    add esp, 4
    popa
    sti
    iret

section .note.GNU-stack noalloc noexec nowrite progbits

