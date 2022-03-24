#ifndef PS2_H
#define PS2_H

#include <stdbool.h>
#include <stdint.h>

#include "ports.h"
#include "serial.h"

#define CMD_PORT  0x64
#define DATA_PORT 0x60

bool ps2_write(uint32_t port, uint8_t b);
uint8_t ps2_read(uint32_t port);

#endif
