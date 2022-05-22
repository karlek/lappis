#ifndef USERLAND_H
#define USERLAND_H

#include <stdint.h>
#include "tinyprintf.h"

void sys_print(uint8_t *s, uint64_t len);

void yay_userland();

#endif
