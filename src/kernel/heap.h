#ifndef HEAP_H
#define HEAP_H

#include <stdint.h>

#include "serial.h"

extern uint32_t KERNEL_DATA_ADDR;
extern uint32_t KERNEL_DATA_END_ADDR;

extern uint32_t USERLAND_ADDR;
extern uint32_t USERLAND_END_ADDR;

void init_heap();
void init_userland_heap();

void* malloc(uint64_t size);
void* userland_malloc(uint64_t size);

#endif
