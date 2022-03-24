#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "ports.h"
#include "tinyprintf.h"
#include "string.h"

#define SERIAL_COM1_PORT 0x3F8
#define SERIAL_COM2_PORT 0x2F8

#define debug(...)  debug_context(__FILE__, __func__, __LINE__, __VA_ARGS__)
#define error(...)  error_context(__FILE__, __func__, __LINE__, __VA_ARGS__)

bool init_serial(uint16_t port);

void error_context(uint8_t* filename, const uint8_t* func_name, uint32_t linenr, uint8_t* format, ...);
void debug_context(uint8_t* filename, const uint8_t* func_name, uint32_t linenr, uint8_t *format, ...);

void serial_debug_write_byte(void* p, char c);

void debug_buffer(const uint8_t* /*buffer*/, size_t /*size*/);
