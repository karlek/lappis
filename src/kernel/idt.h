#ifndef IDT_H
#define IDT_H

#include <stdint.h>

#include "drivers/ata.h"
#include "drivers/keyboard.h"
#include "drivers/mouse.h"
#include "pic.h"
#include "ps2.h"

#define IDT_MAX_DESCRIPTORS 256

// Defined in idt.asm
void num_to_error_name(uint8_t interrupt_number, uint8_t* error_name);
void idt_init();
void sleep(uint64_t ms);

#endif
