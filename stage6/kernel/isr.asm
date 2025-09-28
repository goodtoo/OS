[BITS 32]
GLOBAL isr0
GLOBAL irq0
GLOBAL irq1
GLOBAL isr_default
GLOBAL isr_stub_noerr
GLOBAL isr_stub_err

extern isr_handler
extern sched_need_switch
extern sched_next_esp_val

section .text

; ===== 兜底入口 =====
; 无错误码：直接返回
isr_default:
isr_stub_noerr:
    iret

; 有错误码：丢弃 4 字节后返回
isr_stub_err:
    add esp, 4
    iret

; ===== 异常向量 0（示例）=====
isr0:
    cli
    pusha
    ; C 原型：void isr_handler(uint32_t vec, uint32_t* esp_ptr)
    push esp              ; arg1 = IRQ栈ESP
    mov eax, 0
    push eax              ; arg0 = vec
    call isr_handler
    add esp, 8

    ; --- 分支：是否需要任务切换 ---
    cmp dword [sched_need_switch], 0
    je .no_sw0

    ; 需要切换：把 esp 切到“新任务的假栈”
    mov eax, [sched_next_esp_val]
    mov esp, eax
    mov dword [sched_need_switch], 0

    ; 新任务假栈布局：[EDI..EAX][VECTOR][EIP][CS][EFLAGS]
    popa                  ; 弹出 EDI..EAX
    add esp, 4            ; 丢掉伪造的 VECTOR
    sti
    iret

.no_sw0:
    ; 不切换：仍在原 IRQ 栈上（此栈没有 VECTOR）
    popa
    sti
    iret


; ===== IRQ0：PIT 时钟 =====
irq0:
    cli
    pusha
    push esp
    mov eax, 32
    push eax
    call isr_handler
    add esp, 8

    cmp dword [sched_need_switch], 0
    je .no_sw1

    mov eax, [sched_next_esp_val]
    mov esp, eax
    mov dword [sched_need_switch], 0

    popa
    add esp, 4            ; 丢掉伪造的 VECTOR
    sti
    iret

.no_sw1:
    popa
    sti
    iret


; ===== IRQ1：键盘 =====
irq1:
    cli
    pusha
    push esp
    mov eax, 33
    push eax
    call isr_handler
    add esp, 8

    ; 键盘中断不触发调度
    popa
    sti
    iret

section .note.GNU-stack noalloc noexec nowrite progbits

