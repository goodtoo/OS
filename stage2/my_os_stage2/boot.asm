[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    lgdt [gdt_descriptor]

    ; 开启保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 跳转到保护模式代码段
    jmp CODE_SEG:init_pm

[BITS 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; 打印字符串到显存
    mov esi, message
    mov edi, 0xB8000
.next:
    lodsb
    test al, al
    je .done
    mov [edi], al
    inc edi
    mov byte [edi], 0x07
    inc edi
    jmp .next
.done:
    hlt
    jmp $

message db "Entered Protected Mode!", 0

gdt_start:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

gdt_code equ gdt_start + 8
gdt_data equ gdt_start + 16

times 510 - ($ - $$) db 0
dw 0xAA55
