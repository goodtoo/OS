#include <stdint.h>

#define IDT_SIZE 256
static inline void outb(uint16_t p, uint8_t v){ __asm__ __volatile__("outb %0,%1"::"a"(v),"Nd"(p)); }
static inline uint8_t inb(uint16_t p){ uint8_t r; __asm__ __volatile__("inb %1,%0":"=a"(r):"Nd"(p)); return r; }

struct idt_entry { uint16_t off_lo, sel; uint8_t zero, type; uint16_t off_hi; } __attribute__((packed));
struct idt_ptr   { uint16_t limit; uint32_t base; } __attribute__((packed));

extern void isr0(); extern void irq0(); extern void irq1(); extern void isr_default();

static struct idt_entry idt[IDT_SIZE];
static struct idt_ptr   idtp;

void isr_handler(uint32_t vec){
    volatile uint16_t *vm = (uint16_t*)0xB8000;
    static int pos = 160;
    if (vec==32){ outb(0x20,0x20); vm[pos++] = 0x0E00|'*'; }
    else if (vec==33){ (void)inb(0x60); outb(0x20,0x20); vm[pos++] = 0x0A00|'#'; }
    else { outb(0x20,0x20); vm[pos++] = 0x4F00|'E'; }
}

static void set_gate(int n, uint32_t h){
    idt[n].off_lo = h & 0xFFFF;
    idt[n].sel    = 0x08;
    idt[n].zero   = 0;
    idt[n].type   = 0x8E;
    idt[n].off_hi = (h>>16)&0xFFFF;
}

void idt_init(void){
    for(int i=0;i<IDT_SIZE;i++) set_gate(i,(uint32_t)isr_default);
    set_gate(0,(uint32_t)isr0);
    set_gate(32,(uint32_t)irq0);
    set_gate(33,(uint32_t)irq1);
    idtp.limit = sizeof(idt)-1;
    idtp.base  = (uint32_t)idt;
    __asm__ __volatile__("lidt (%0)"::"r"(&idtp));
}

void pic_remap(void){
    outb(0x21,0xFF); outb(0xA1,0xFF);
    outb(0x20,0x11); outb(0xA0,0x11);
    outb(0x21,0x20); outb(0xA1,0x28);
    outb(0x21,0x04); outb(0xA1,0x02);
    outb(0x21,0x01); outb(0xA1,0x01);
    outb(0x21,0xFC); outb(0xA1,0xFF);
}

void pit_init(void){
    uint16_t div = (uint16_t)(1193182/100);
    outb(0x43,0x36);
    outb(0x40,div&0xFF);
    outb(0x40,div>>8);
}

