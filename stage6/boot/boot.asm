; boot/boot.asm — 读取内核 -> 采集E820 -> 进PM -> 显示PJ -> 跳 0x1000
[bits 16]
[org 0x7C00]

%ifndef KERNEL_SECTORS
    %define KERNEL_SECTORS 32
%endif

KERNEL_LOAD_SEG equ 0x0000
KERNEL_LOAD_OFF equ 0x1000

%macro PUTCH 1
    mov ah, 0x0E
    mov al, %1
    mov bh, 0
    mov bl, 0x07
    int 0x10
%endmacro

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [BootDrive], dl

    PUTCH 'A'

    ; 关闭 NMI（CMOS 索引端口 0x70 的 bit7 = 1）
    in   al, 0x70
    or   al, 0x80
    out  0x70, al

    ; 开 A20（端口 0x92）
    in  al, 0x92
    or  al, 0000_0010b
    out 0x92, al

    ; ---------- E820（写到 0000:5000，计数到 0x4FF0） ----------
    xor ax, ax
    mov es, ax
    mov di, 0x5000
    xor ebx, ebx
    mov word [0x4FF0], 0
.e820_loop:
    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 24
    int 0x15
    jc  .e820_done
    cmp eax, 0x534D4150
    jne .e820_done
    add di, 24
    inc word [0x4FF0]
    test ebx, ebx
    jnz .e820_loop
.e820_done:

    ; ---------- 读内核到 0000:1000 ----------
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    mov bx, KERNEL_LOAD_OFF
    call read_kernel_chs
    jc   .read_fail
    PUTCH 'C'

    jmp  .enter_pm

.enter_pm:
    ; 切换到保护模式
    lgdt [gdt_descriptor]
    mov eax, cr0
    or  eax, 1
    mov cr0, eax
    ; 16->32 远跳：66 EA imm32:imm16
    db 0x66, 0xEA
    dd pm_entry
    dw CODE_SEL

.read_fail:
    PUTCH 'E'
.hang16: hlt
    jmp .hang16

; ----------------------------
; 32-bit Protected Mode
; ----------------------------
[bits 32]
pm_entry:
    mov ax, DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; 左上角 'PJ'
    mov word [0xB8000 + 0*2], 0x0F50      ; 'P'
    mov word [0xB8000 + 1*2], 0x0F4A      ; 'J'

    ; 跳到 0x1000 执行 C 内核
    mov eax, 0x00001000
    jmp eax

.hang32: hlt
    jmp .hang32

; ----------------------------
; CHS 读 若干扇区到 ES:BX
; ----------------------------
[bits 16]
read_kernel_chs:
    pusha
    mov ah, 0x00
    mov dl, [BootDrive]
    int 0x13

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov dl, [BootDrive]
    int 0x13
    jnc .ok
    ; retry
    mov ah, 0x00
    mov dl, [BootDrive]
    int 0x13
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov dl, [BootDrive]
    int 0x13
    jc .fail
.ok:  popa
     clc
     ret
.fail:
     popa
     stc
     ret

; ----------------------------
; GDT（null + code + data）
; ----------------------------
[bits 16]
gdt_start:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF           ; code base=0, limit=4G
    dq 0x00CF92000000FFFF           ; data base=0, limit=4G
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEL equ 0x08
DATA_SEL equ 0x10

BootDrive: db 0

times 510 - ($ - $$) db 0
dw 0xAA55

