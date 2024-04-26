#ifndef VIDEO_H
#define VIDEO_H

#include <stdint.h>

#include "memcpy.h"
#include "terminal-font.h"

extern uint32_t FRAME_BUFFER_ADDR;

#define WIDTH        1280
#define HEIGHT       1024

void set_frame(uint8_t* frame);
void set_pixel(uint32_t x, uint32_t y, const uint8_t color[4]);
void draw_string(const uint8_t* str, uint32_t x, uint32_t y, uint8_t* color);
void draw_char(uint8_t c, uint32_t x, uint32_t y, uint8_t* color);

#endif
