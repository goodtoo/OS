// kernel/idt.c
#include <stdint.h>

#define IDT_SIZE 256

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ __volatile__("outb %0,%1" : : "a"(val), "Nd"(port));
}
static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ __volatile__("inb %1,%0" : "=a"(ret) : "Nd"(port));
    return ret;
}

struct idt_entry {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  zero;
    uint8_t  type_attr;
    uint16_t offset_high;
} __attribute__((packed));

struct idt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

extern void isr0();
extern void irq0();
extern void irq1();

static struct idt_entry idt[IDT_SIZE];
static struct idt_ptr   idtp;

// C 层统一处理中断
void isr_handler(uint32_t vec) {
    volatile uint16_t *vmem = (uint16_t*)0xB8000;
    static int pos = 160; // 第二行

    if (vec == 32) {               // PIT
        vmem[pos++] = 0x0E00 | '*';
        outb(0x20, 0x20);          // EOI
    } else if (vec == 33) {        // 键盘
        (void)inb(0x60);           // 读扫描码
        vmem[pos++] = 0x0A00 | '#';
        outb(0x20, 0x20);          // EOI (主片)
    } else {                       // 其他（异常等）
        vmem[pos++] = 0x4F00 | 'E';
        outb(0x20, 0x20);
    }
}

static void set_idt_entry(int num, uint32_t base) {
    idt[num].offset_low  = base & 0xFFFF;
    idt[num].selector    = 0x08;   // CODE_SEL
    idt[num].zero        = 0;
    idt[num].type_attr   = 0x8E;   // present|DPL0|32-bit int gate
    idt[num].offset_high = (base >> 16) & 0xFFFF;
}

void idt_init() {
    for (int i = 0; i < IDT_SIZE; i++) set_idt_entry(i, 0);
    set_idt_entry(0,  (uint32_t)isr0);
    set_idt_entry(32, (uint32_t)irq0);
    set_idt_entry(33, (uint32_t)irq1);

    idtp.limit = sizeof(idt) - 1;
    idtp.base  = (uint32_t)&idt;
    __asm__ __volatile__("lidtl (%0)" :: "r"(&idtp));
}

void pic_remap() {
    outb(0x21, 0xFF); outb(0xA1, 0xFF);    // 先全屏蔽

    outb(0x20, 0x11); outb(0xA0, 0x11);    // ICW1
    outb(0x21, 0x20); outb(0xA1, 0x28);    // ICW2
    outb(0x21, 0x04); outb(0xA1, 0x02);    // ICW3
    outb(0x21, 0x01); outb(0xA1, 0x01);    // ICW4

    outb(0x21, 0xFC);                      // 允许 IRQ0/1
    outb(0xA1, 0xFF);                      // 从片全屏蔽
}

void pit_init() {
    uint16_t div = (uint16_t)(1193182 / 100); // 100Hz
    outb(0x43, 0x36);               // 通道0, lobyte/hibyte, 模式3
    outb(0x40, div & 0xFF);
    outb(0x40, div >> 8);
}

