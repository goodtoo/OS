[BITS 16]
[ORG 0x1000]

start:
    mov si, message
.print:
    lodsb
    or al, al
    jz halt
    mov ah, 0x0E
    int 0x10
    jmp .print

halt:
    jmp $

message: db 'Hello from Assembly Kernel!', 0
