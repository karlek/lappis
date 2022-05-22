#ifndef ELF2_H
#define ELF2_H

#include <stdint.h>
#include <stddef.h>

#include "heap.h"
#include "format/zip.h"
#include "elf.h"
#include "elf2.c"

void run_userland(uint8_t* userland_obj, size_t userland_obj_size);

#endif
