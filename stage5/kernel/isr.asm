[BITS 32]
GLOBAL isr0
GLOBAL irq0
GLOBAL irq1
GLOBAL isr_default
GLOBAL isr_stub_noerr
GLOBAL isr_stub_err

extern isr_handler

section .text

; 兜底：无错误码
isr_default:
isr_stub_noerr:
    iret

; 兜底：有错误码
isr_stub_err:
    add esp, 4
    iret

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

