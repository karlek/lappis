#ifndef HEAP_H
#define HEAP_H

#include <stdint.h>

#include "serial.h"

extern void* P2_KERNEL_DATA_ADDR_EXPORT;
extern uint64_t P2_USERLAND_ADDR_EXPORT;

// Kernel stack:       0x4000000 - 0x4800000
// Frame buffer:       0x4800000 - 0x4e00000

void init_heap();
void* malloc(uint64_t size);
void* userland_alloc(uint64_t addr, uint64_t size);
uint64_t USERLAND();

#endif
