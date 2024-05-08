#ifndef ATA_H
#define ATA_H

#include <stdint.h>

#include "pic.h"
#include "print.h"
#include "string.h"
#include "terminal-font.h"

bool circ_buf_pop(uint8_t* data);

#endif
