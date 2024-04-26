#ifndef HEAP_H
#define HEAP_H

#include <stdint.h>

#include "serial.h"

// 59MiB heap
#define HEAP_START 0x300000
#define HEAP_END   0x3e00000

// Kernel stack:       0x4000000 - 0x4800000
// Frame buffer:       0x4800000 - 0x4e00000

void* malloc(uint64_t size);

#endif
