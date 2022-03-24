#ifndef SERIAL_H
#define SERIAL_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "ports.h"
#include "string.h"
#include "tinyprintf.h"

#define SERIAL_COM1_PORT 0x3F8
#define SERIAL_COM2_PORT 0x2F8

#define debug(...)  debug_context(__FILE__, __func__, __LINE__, __VA_ARGS__)
#define error(...)  error_context(__FILE__, __func__, __LINE__, __VA_ARGS__)

bool init_serial(uint16_t port);

void error_context(uint8_t* filename, const uint8_t* func_name, uint32_t linenr, uint8_t* format, ...);
void debug_context(uint8_t* filename, const uint8_t* func_name, uint32_t linenr, uint8_t *format, ...);

void serial_debug_write_byte(void* p, char c);

void debug_buffer(const uint8_t* /*buffer*/, size_t /*size*/);

#endif
