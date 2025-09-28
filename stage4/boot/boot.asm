; boot/boot.asm — A -> C -> S/Z -> P -> J -> 跳 0x1000
[BITS 16]
[ORG 0x7C00]

%ifndef KERNEL_SECTORS
    %define KERNEL_SECTORS 32
%endif

KERNEL_LOAD_SEG equ 0x0000
KERNEL_LOAD_OFF equ 0x1000

%macro PUTC16 2
    push ds
    mov  ax, 0xB800
    mov  ds, ax
    mov  word [%1], 0x0F00 + %2
    pop  ds
%endmacro

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [BootDrive], dl

    ; A：进入引导器
    PUTC16 0, 'A'

    ; 开 A20
    in  al, 0x92
    or  al, 0000_0010b
    out 0x92, al

    ; 目标缓冲：0000:1000
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    mov bx, KERNEL_LOAD_OFF

    ; === 强制用 CHS 读取 ===
    call read_kernel_chs
    jc   .read_fail
    PUTC16 2, 'C'

    ; 检查 0x1000 首字节是否为 0x55
    call check_kernel_byte

    ; 进入保护模式
    lgdt [gdt_descriptor]
    mov eax, cr0
    or  eax, 1
    mov cr0, eax
    jmp CODE_SEL:pm_entry

.read_fail:
    PUTC16 0, 'E'
    jmp $

; ----------------------------
; 32-bit Protected Mode
; ----------------------------
[BITS 32]
pm_entry:
    mov ax, DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; P：进入保护模式
    mov word [0xB8002], 0x0F50   ; 'P'
    ; J：准备跳内核
    mov word [0xB8004], 0x0F4A   ; 'J'

    ; 跳到 0x1000
    mov eax, 0x00001000
    jmp eax

.hang:
    hlt
    jmp .hang

; ----------------------------
; 检查内核首字节
; ----------------------------
[BITS 16]
check_kernel_byte:
    push ds
    mov  ax, KERNEL_LOAD_SEG
    mov  ds, ax
    mov  al, [KERNEL_LOAD_OFF]
    pop  ds
    push ds
    mov  ax, 0xB800
    mov  ds, ax
    cmp  al, 0x55
    jne  .zbad
    mov  word [6], 0x0F53        ; 'S'
    jmp  .done
.zbad:
    mov  word [6], 0x0F5A        ; 'Z'
.done:
    pop  ds
    ret

; ----------------------------
; CHS 读：道0 头0，从扇区2开始，连续读 KERNEL_SECTORS 个
; 返回：CF=0 成功，CF=1 失败
; ----------------------------
read_kernel_chs:
    pusha

    ; 先 reset 一次，避免上一次失败残留状态
    mov ah, 0x00
    mov dl, [BootDrive]
    int 0x13

    mov ah, 0x02                  ; 读扇区函数
    mov al, KERNEL_SECTORS        ; **修正：装入常量，不要用 [KERNEL_SECTORS]**
    mov ch, 0                     ; 柱面0
    mov dh, 0                     ; 磁头0
    mov cl, 2                     ; 从扇区2开始（扇区1是 MBR）
    mov dl, [BootDrive]           ; 驱动号
    int 0x13
    jnc .ok

    ; 失败则再 reset + 重试一次
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

.ok:
    popa
    clc
    ret
.fail:
    popa
    stc
    ret

; ----------------------------
; GDT
; ----------------------------
[BITS 16]
gdt_start:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF         ; code
    dq 0x00CF92000000FFFF         ; data
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEL equ 0x08
DATA_SEL equ 0x10

BootDrive: db 0

times 510 - ($ - $$) db 0
dw 0xAA55

