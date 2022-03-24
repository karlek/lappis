#include <stdint.h>

#include "memcpy.h"
#include "terminal-font.h"

#define FRAME_BUFFER 0x4800000
#define WIDTH        1280
#define HEIGHT       1024

void set_frame(uint8_t* frame);
void set_pixel(uint32_t x, uint32_t y, const uint8_t color[4]);
void draw_string(const uint8_t* str, uint32_t x, uint32_t y, uint8_t* color);
void draw_char(uint8_t c, uint32_t x, uint32_t y, uint8_t* color);
