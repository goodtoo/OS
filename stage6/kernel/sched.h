#pragma once
#include <stdint.h>

typedef void (*task_func_t)(void);

void    sched_init(void);
int     sched_create(task_func_t entry, const char* name);
void    sched_on_tick(uint32_t *irq_stack_esp);

/* 供汇编访问的全局标记（在 sched.c 定义） */
extern volatile uint32_t sched_need_switch;
extern volatile uint32_t sched_next_esp_val;
