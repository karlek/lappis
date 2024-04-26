#ifndef HEAP_H
#define HEAP_H

#include <stdint.h>

#include "serial.h"

extern uint32_t KERNEL_DATA_ADDR;
extern uint32_t KERNEL_DATA_END_ADDR;
extern uint32_t USERLAND_ADDR;

void * USERLAND_START();

void init_heap();

void* malloc(uint64_t size);

void* userland_alloc(uint64_t addr, uint64_t size);

#endif
