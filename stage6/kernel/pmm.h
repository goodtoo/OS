#pragma once
#include <stdint.h>

#define PAGE_SIZE 4096

void pmm_init(void);
void* kmalloc_page(void);
void  kfree_page(void* p);

uint32_t pmm_total_pages(void);
uint32_t pmm_free_pages(void);

