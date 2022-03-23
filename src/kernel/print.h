#include <stdint.h>

#include "heap.h"
#include "video.h"
#include "string.h"

void kprintf(uint32_t x, uint32_t y, uint8_t* color, uint8_t* format, ...);
void print_box(uint8_t* s, uint32_t x, uint32_t y, uint8_t* color);
