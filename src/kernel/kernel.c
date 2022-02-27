#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "multiboot.c"

#include "string.c"
#include "ports.c"
#include "serial.c"
#include "heap.c"
#include "terminal-font.h"
#include "video.c"
#include "mandel.c"
#include "print.c"
#include "pic.c"
#include "idt.c"
#include "fpu.c"
#include "format/zip.c"

void warn_interrupt(uint8_t interrupt_number) {
	uint8_t red[4] = {255, 0, 0, 0xff};
	uint8_t* error_name = malloc(256);
	num_to_error_name(interrupt_number, error_name);

	uint8_t* tmp = malloc(256);
	sprintf(tmp, "Warning! Interrupt occurred: %s [%d/%x]", error_name, interrupt_number, interrupt_number);
	print_box(tmp, LARGE_FONT_CELL_WIDTH, 2, red);
}

void end_of_execution() {
	uint8_t green[4] = {0, 255, 0, 0xff};
	print_box("End of execution.", LARGE_FONT_CELL_WIDTH, 2, green);
}

void main(struct multiboot_info* boot_info) {
	init_serial(SERIAL_COM1_PORT);
	init_serial(SERIAL_COM2_PORT);

	debug("Kernel started.");
	// Setup interrupts.
	idt_init();

	// Enable floating point operations.
	enable_fpu();

	ide_dev dev = {
		ATA_PRIMARY_BUS,
		ATA_PRIMARY_DRIVE,
		ATA_PRIMARY_IO,
	};

	debug("> ATA");
	uint8_t *read_buf = malloc(1024);
	ata_read(read_buf, 0, 2, &dev);
	debug("< ATA");

	while(1) {};
}

void test_kernel_printing() {
	for (uint8_t i = 0; i <= 59; i++) {
		uint8_t *num_str = malloc(256);
		itoa(i, num_str);
		kprint(num_str);
	}
}
