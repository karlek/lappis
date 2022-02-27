#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "multiboot.c"

#include "string.c"
#include "ports.c"
#include "serial.c"
#include "terminal-font.h"
#include "video.c"
#include "mandel.c"
#include "print.c"
#include "pic.c"
#include "idt.c"
#include "fpu.c"
#include "format/zip.c"

void warn_interrupt(int interrupt_number) {
	unsigned char red[4] = {255, 0, 0, 0xff};
	unsigned char error_name[256] = {0};
	num_to_error_name(interrupt_number, error_name);

	char tmp[256] = {0};
	sprintf(tmp, "Warning! Interrupt occurred: %s [%d/%x]", error_name, interrupt_number, interrupt_number);
	print_box(tmp, LARGE_FONT_CELL_WIDTH, 2, red);
}

void end_of_execution() {
	unsigned char green[4] = {0, 255, 0, 0xff};
	print_box("End of execution.", LARGE_FONT_CELL_WIDTH, 2, green);
}

void main(struct multiboot_info* boot_info) {
	// Setup interrupts.
	idt_init();

	// Enable floating point operations.
	enable_fpu();

	print_box("Press any key:", 700, 0, NULL);

	ide_dev dev = {
		ATA_PRIMARY_BUS,
		ATA_PRIMARY_DRIVE,
		ATA_PRIMARY_IO,
	};

	uint8_t read_buf[1024] = {0};
	uint32_t cur = 0;

	ata_read(read_buf, 0, 2, &dev);
	for (int i = 0; i < 5; i++) {
		zip_t zip;
		read_zip(read_buf, &cur, &zip);
		printf("%s", 0, 200+i*20, NULL, zip.file_name);
	}

	/* draw_mandel(); */

	end_of_execution();
	while(1) {};
}
