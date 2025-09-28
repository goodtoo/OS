#include "pmm.h"
#include <stdint.h>

#define E820_COUNT_ADDR  ((volatile uint16_t*)0x00004FF0)
#define E820_TABLE_ADDR  ((volatile uint8_t*) 0x00005000)

#define MAX_PHYS_MB   64u
#define MAX_PAGES     ((MAX_PHYS_MB*1024*1024)/PAGE_SIZE)
#define BITMAP_BYTES  (MAX_PAGES/8)

static uint8_t  bitmap[BITMAP_BYTES];
static uint32_t total_pages = MAX_PAGES;
static uint32_t free_pages_cnt = 0;

static inline void bm_set(uint32_t i){ bitmap[i>>3] |=  (1u<<(i&7)); }
static inline void bm_clr(uint32_t i){ bitmap[i>>3] &= ~(1u<<(i&7)); }
static inline int  bm_tst(uint32_t i){ return (bitmap[i>>3]>>(i&7))&1u; }

typedef struct __attribute__((packed)) {
    uint32_t base_lo, base_hi;
    uint32_t len_lo,  len_hi;
    uint32_t type;       // 1=Usable
    uint32_t ext_attr;
} e820_t;

extern uint8_t _kernel_start, _kernel_end;

static void mark_region(uint64_t base, uint64_t len, int usable){
    uint64_t end = base + len;
    uint64_t cap = (uint64_t)MAX_PHYS_MB*1024u*1024u;
    if (end > cap) end = cap;
    if (base >= end) return;
    uint32_t first = (uint32_t)(base / PAGE_SIZE);
    uint32_t last  = (uint32_t)((end  + PAGE_SIZE-1)/PAGE_SIZE);
    if (last > MAX_PAGES) last = MAX_PAGES;
    for (uint32_t i=first; i<last; ++i){
        if (usable) bm_clr(i); else bm_set(i);
    }
}

void pmm_init(void){
    for (uint32_t i=0;i<BITMAP_BYTES;i++) bitmap[i]=0xFF;

    uint16_t cnt = *E820_COUNT_ADDR;
    const e820_t* tbl = (const e820_t*)E820_TABLE_ADDR;

    for (uint16_t i=0; i<cnt; ++i){
        uint64_t base = ((uint64_t)tbl[i].base_hi<<32) | tbl[i].base_lo;
        uint64_t len  = ((uint64_t)tbl[i].len_hi <<32) | tbl[i].len_lo;
        if (tbl[i].type == 1) mark_region(base, len, 1);
    }

    mark_region(0, 0x100000, 0); // 低端1MB
    mark_region((uintptr_t)&_kernel_start, (uintptr_t)&_kernel_end - (uintptr_t)&_kernel_start, 0);

    free_pages_cnt = 0;
    for (uint32_t i=0;i<MAX_PAGES;i++) if (!bm_tst(i)) free_pages_cnt++;
}

void* kmalloc_page(void){
    for (uint32_t i=0;i<MAX_PAGES;i++){
        if (!bm_tst(i)){
            bm_set(i);
            if (free_pages_cnt) free_pages_cnt--;
            return (void*)(i*PAGE_SIZE);  // 未开分页：物理=虚拟
        }
    }
    return 0;
}

void kfree_page(void* p){
    uint32_t addr = (uint32_t)p;
    if (addr % PAGE_SIZE) return;
    uint32_t idx = addr / PAGE_SIZE;
    if (idx < MAX_PAGES && bm_tst(idx)){
        bm_clr(idx);
        free_pages_cnt++;
    }
}

uint32_t pmm_total_pages(void){ return total_pages; }
uint32_t pmm_free_pages(void){  return free_pages_cnt; }

