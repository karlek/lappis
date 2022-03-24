#ifndef PRINT_H
#define PRINT_H

#include <stdint.h>

#include "heap.h"
#include "string.h"
#include "video.h"

void kprintf(uint32_t x, uint32_t y, uint8_t* color, uint8_t* format, ...);
void print_box(uint8_t* s, uint32_t x, uint32_t y, uint8_t* color);

#endif
