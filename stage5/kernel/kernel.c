// kernel/kernel.c — 任务三：兜底 IDT -> （可选）打开 NMI -> PMM -> 正式 IDT/PIC/PIT
#include <stdint.h>
#include "pmm.h"

// 正式 IDT/PIC/PIT（在 idt.c 中实现）
void idt_init();
void pic_remap();
void pit_init();

// ===== 兜底 IDT（最早安装，防 NMI/异常触发 triple fault）=====
struct idt_entry {
    uint16_t off_lo, sel;
    uint8_t  zero, type;
    uint16_t off_hi;
} __attribute__((packed));

struct idt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

extern void isr_stub_noerr();  // isr.asm 提供
extern void isr_stub_err();    // isr.asm 提供

static void fallback_idt_install(void){
    static struct idt_entry fb_idt[256];
    static struct idt_ptr   fb_idtr;
    uint32_t h_noerr = (uint32_t)isr_stub_noerr;
    uint32_t h_err   = (uint32_t)isr_stub_err;

    for(int i=0;i<256;i++){
        fb_idt[i].off_lo = h_noerr & 0xFFFF;
        fb_idt[i].sel    = 0x08;     // CODE_SEL
        fb_idt[i].zero   = 0;
        fb_idt[i].type   = 0x8E;     // int gate, present, DPL0
        fb_idt[i].off_hi = (h_noerr >> 16) & 0xFFFF;
    }
    // 带错误码的异常：8,10,11,12,13,14,17,30
    int errv[] = {8,10,11,12,13,14,17,30};
    for(unsigned k=0;k<sizeof(errv)/sizeof(errv[0]);k++){
        int v = errv[k];
        fb_idt[v].off_lo = h_err & 0xFFFF;
        fb_idt[v].off_hi = (h_err >> 16) & 0xFFFF;
    }

    fb_idtr.limit = sizeof(fb_idt) - 1;
    fb_idtr.base  = (uint32_t)fb_idt;
    __asm__ __volatile__("lidt (%0)" :: "r"(&fb_idtr));
}
// ===== 兜底 IDT 结束 =====

// 可选：内核装好兜底 IDT 后再打开 NMI
static inline void nmi_enable(void){
    unsigned char a;
    __asm__ __volatile__("inb $0x70,%0" : "=a"(a));
    a &= 0x7F;                            // 清 bit7
    __asm__ __volatile__("outb %0,$0x70" :: "a"(a));
}

static void putc_at(int row, int col, char ch, uint8_t attr){
    ((volatile uint16_t*)0xB8000)[row*80+col] = ((uint16_t)attr<<8) | (uint8_t)ch;
}
static void print(const char* s, int row, int col){
    volatile uint16_t* v = (uint16_t*)0xB8000;
    int p = row*80 + col;
    while(*s) v[p++] = 0x0F00 | (uint8_t)*s++;
}
static void print_hex(uint32_t x, int row, int col){
    static const char* hex="0123456789ABCDEF";
    for(int i=0;i<8;i++){
        int sh=(7-i)*4;
        putc_at(row,col+i,hex[(x>>sh)&0xF],0x0E);
    }
}

void kernel_main() {
    // 1) 最先装兜底 IDT（关键！）
    fallback_idt_install();

    // 2) （可选）现在再打开 NMI（boot 里已关闭）
    nmi_enable();

    // UI 标记：确认进入内核
    print("OK1",   1, 0);
    print("HELLO", 3, 0);

    // 3) PMM 初始化 & 自检
    pmm_init();
    void* p1 = kmalloc_page();
    void* p2 = kmalloc_page();
    uint32_t freep = pmm_free_pages();
    print("Stage 3: IDT+PIC+PIT+PMM", 1, 5);
    print("PMM free pages: 0x", 2, 0);
    print_hex(freep, 2, 18);
    if (p1) kfree_page(p1);
    if (p2) kfree_page(p2);

    // 4) 正式 IDT/PIC/PIT（中断表 & 定时器）
    idt_init();
    pic_remap();
    pit_init();

    __asm__ __volatile__("sti");     // 最后再开中断
    for(;;) __asm__ __volatile__("hlt");
}

