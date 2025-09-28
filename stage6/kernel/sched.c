#include "sched.h"
#include "pmm.h"
#include <stdint.h>

#define MAX_TASKS    4
#define CODE_SEL     0x08      // ring0 代码段

typedef struct {
    uint32_t esp;              // 就绪/被中断时的 IRQ 栈顶
    int      used;
    char     name[16];
} task_t;

static task_t tasks[MAX_TASKS];
static int    cur = -1;
static int    task_count = 0;

/* 汇编可见：是否需要切换，以及切换到哪个 esp */
volatile uint32_t sched_need_switch = 0;
volatile uint32_t sched_next_esp_val = 0;

/* 简易输出 */
static void print_at(const char* s, int row, int col){
    volatile uint16_t* v=(uint16_t*)0xB8000; int p=row*80+col;
    while(*s) v[p++] = 0x0F00 | (uint8_t)*s++;
}

/* 两个示例任务 */
static void task1_body(void){
    volatile uint16_t* v=(uint16_t*)0xB8000; int pos=80*8;
    for(;;){ v[pos++] = 0x0A00 | '1'; __asm__ __volatile__("hlt"); }
}
static void task2_body(void){
    volatile uint16_t* v=(uint16_t*)0xB8000; int pos=80*9;
    for(;;){ v[pos++] = 0x0B00 | '2'; __asm__ __volatile__("hlt"); }
}

/* ★ 关键：构造“假栈”与 isr.asm 退出序列匹配
   isr.asm 在“真的发生切换”时执行：
      popa                ; EDI..EAX
      add esp, 4          ; 丢掉 [VECTOR]
      iret                ; 弹出 [EIP][CS][EFLAGS]
   因此假栈从低地址到高地址布局为：
      [EDI][ESI][EBP][ESP(dmy)][EBX][EDX][ECX][EAX][VECTOR][EIP][CS=0x08][EFLAGS]
   返回的 ESP 必须指向 [EDI]。
*/
typedef void (*task_func_t)(void);
static uint32_t build_initial_esp(task_func_t entry){
    uint8_t* page = (uint8_t*)kmalloc_page();
    uint32_t top  = (uint32_t)page + PAGE_SIZE;
    uint32_t *sp  = (uint32_t*)top;

    /* iret 帧（高地址端） */
    *--sp = 0x00000202;          // EFLAGS（IF=1）
    *--sp = (uint32_t)CODE_SEL;  // CS = 0x08 (ring0)
    *--sp = (uint32_t)entry;     // EIP = 任务入口

    /* 伪中断向量（isr.asm 会 add esp,4 丢弃） */
    *--sp = 32;                  // VECTOR (IRQ0)

    /* pusha 框（低地址端 -> 高地址端），popa 恢复顺序 EDI..EAX */
    *--sp = 0x00000000;          // EAX
    *--sp = 0x00000000;          // ECX
    *--sp = 0x00000000;          // EDX
    *--sp = 0x00000000;          // EBX
    *--sp = 0xDEADBEEF;          // ESP (dummy，占位，不被使用)
    *--sp = 0x00000000;          // EBP
    *--sp = 0x00000000;          // ESI
    *--sp = 0x00000000;          // EDI

    return (uint32_t)sp;         // 指向 [EDI]
}

/* API 实现 */
void sched_init(void){
    // 清零任务表
    for (int i=0;i<MAX_TASKS;i++){
        tasks[i].esp = 0;
        tasks[i].used = 0;
        for (int j=0;j<16;j++) tasks[i].name[j]=0;
    }
    cur = -1;
    task_count = 0;

    // 创建两个演示任务
    sched_create(task1_body, "task1");
    sched_create(task2_body, "task2");

    print_at("Scheduler: 2 tasks", 7, 0);
}

int sched_create(task_func_t entry, const char* name){
    for (int i=0;i<MAX_TASKS;i++){
        if (!tasks[i].used){
            tasks[i].used = 1;
            tasks[i].esp  = build_initial_esp(entry);
            int j=0; for(; j<15 && name && name[j]; j++) tasks[i].name[j]=name[j];
            tasks[i].name[j]=0;
            task_count++;
            if (cur < 0) cur = i;         // 第一个任务作为“当前”
            return i;
        }
    }
    return -1;
}

void sched_on_tick(uint32_t *irq_stack_esp){
    if (cur < 0 || task_count == 0) return;

    // 保存当前任务的 IRQ 栈
    tasks[cur].esp = (uint32_t)irq_stack_esp;

    // 简单轮询
    int nxt = cur;
    for (int k=0;k<MAX_TASKS;k++){
        nxt = (nxt + 1) % MAX_TASKS;
        if (tasks[nxt].used) break;
    }

    if (nxt != cur){
        sched_next_esp_val = tasks[nxt].esp;
        cur = nxt;
        sched_need_switch = 1;
    }
}

