#ifndef HEAP_H
#define HEAP_H

#include <stdint.h>

#include "serial.h"

extern uint32_t KERNEL_DATA_ADDR;
extern uint32_t KERNEL_DATA_END_ADDR;

void init_heap();

// Kernel stack:       0x4000000 - 0x4800000
// Frame buffer:       0x4800000 - 0x4e00000

void* malloc(uint64_t size);

#endif
