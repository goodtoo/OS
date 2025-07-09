[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; 加载 GDT
    lgdt [gdt_descriptor]

    ; 开启保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 跳转到32位模式
    jmp CODE_SEL:init_pm

; ----------------------------
; === 32-bit Protected Mode ===
; ----------------------------
[BITS 32]

init_pm:
    ; 初始化段寄存器
    mov ax, DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; 初始化 IDT
    call init_idt

    ; 初始化 PIC
    call remap_pic

    ; 开启中断
    sti

    ; 调用 C 内核入口
    call kernel_main

.hang:
    hlt
    jmp .hang

; ----------------------------
; IDT 结构
; ----------------------------
init_idt:
    ; 清空 IDT 表
    lea edi, [idt]
    xor eax, eax
    mov ecx, 256
.clear_idt:
    mov [edi], eax
    mov [edi + 4], eax
    add edi, 8
    loop .clear_idt

    ; 设置 ISR 和 IRQ
    ; set_idt_entry(num, handler)
    mov eax, isr0
    call set_idt_entry_0

    mov eax, irq1
    call set_idt_entry_33

    ; 加载 IDT
    lidt [idt_descriptor]
    ret

; ----------------------------
; 设置 IDT 项函数（固定实现）
; ----------------------------
set_idt_entry_0:
    ; 中断 0 (除0异常)
    mov ebx, idt
    jmp set_entry

set_idt_entry_33:
    ; 中断 0x21 (IRQ1 键盘)
    mov ebx, idt
    add ebx, 33 * 8
    jmp set_entry

set_entry:
    mov word [ebx], ax             ; offset[15:0]
    mov word [ebx + 2], CODE_SEL   ; selector
    mov byte [ebx + 4], 0          ; zero
    mov byte [ebx + 5], 0x8E       ; type_attr: present, ring 0, 32-bit int gate
    shr eax, 16
    mov word [ebx + 6], ax         ; offset[31:16]
    ret

; ----------------------------
; PIC 重映射
; ----------------------------
remap_pic:
    ; 初始化主/从 PIC
    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    ; 设置主/从 PIC 中断向量偏移
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al

    ; 主PIC连接从PIC的位置（IRQ2）
    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al

    ; 设置为 8086 模式
    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    ; 打开 IRQ1（键盘中断）
    mov al, 0xFD       ; 1111 1101 -> IRQ1 允许
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al

    ret

; ----------------------------
; GDT 表结构
; ----------------------------
gdt_start:
    dq 0x0000000000000000           ; null descriptor
    dq 0x00CF9A000000FFFF           ; code segment
    dq 0x00CF92000000FFFF           ; data segment
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEL equ 0x08
DATA_SEL equ 0x10

; ----------------------------
; IDT 空表结构
; ----------------------------
idt:
    times 256 dq 0
idt_descriptor:
    dw 256 * 8 - 1
    dd idt

; ----------------------------
; 外部符号声明（由其他文件提供）
; ----------------------------
extern isr0
extern irq1
extern kernel_main

; ----------------------------
; 启动扇区标志
; ----------------------------
times 510 - ($ - $$) db 0
dw 0xAA55
