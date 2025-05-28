[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov ah, 0x02
    mov al, 8         ; 读取8个扇区
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    mov bx, 0x1000
    int 0x13

    jnc jump_kernel
    hlt

jump_kernel:
    push 0x0000
    push 0x1000
    retf

times 510 - ($ - $$) db 0
dw 0xAA55
