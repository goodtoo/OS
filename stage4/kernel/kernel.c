// kernel/kernel.c
#include <stdint.h>

void idt_init();
void pic_remap();
void pit_init();

void kernel_main() {
    // 标记：第二行(行=1, 列=0)写 'K'，黑底白字
    *((volatile uint16_t*)0xB8000 + 80*1 + 0) = 0x0F00 | 'K';

    // 显示标题
    volatile uint16_t* vmem = (uint16_t*)0xB8000;
    const char* msg = "Stage 4: Timer + IRQ ready";
    uint16_t color = 0x0F00;
    for (int i = 0; msg[i]; i++) vmem[i] = color | msg[i];

    // 初始化中断与定时器
    idt_init();
    pic_remap();
    pit_init();

    __asm__ __volatile__("sti"); // 开中断
    for (;;) __asm__ __volatile__("hlt");
}

