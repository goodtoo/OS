[BITS 32]
[GLOBAL isr0]
[GLOBAL irq1]

section .text

; ==========================
; 通用异常处理: isr0（除0错误）
; ==========================
isr0:
    pusha
    ; 显示 E 到屏幕位置 0xB8000
    mov al, 'E'
    mov ah, 0x4F            ; 红底白字
    mov [0xB8000], ax
    popa
    iret

; ==========================
; IRQ1：键盘中断处理程序
; ==========================
irq1:
    pusha

    ; 从端口 0x60 读取键盘扫描码
    in al, 0x60

    ; 将扫描码直接显示到显存 0xB8002（第二字符位置）
    mov ah, 0x0A            ; 绿色字体
    mov [0xB8002], ax

    ; 向主 PIC 发送中断结束信号（EOI）
    mov al, 0x20
    out 0x20, al

    popa
    iret
