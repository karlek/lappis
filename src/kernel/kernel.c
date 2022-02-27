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
	debug("> ATA");





	/* debug_buffer(read_buf, sizeof read_buf); */

	/* debug("> zipfs"); */
	/* zip_fs_t zipfs; */
	/* uint32_t cur = 0; */
	/* read_zip(read_buf, -1, &cur, &zipfs); */
	/* /1* debug(zip.file_name); *1/ */
	/* /1* debug_buffer(zip.uncompressed, zip.uncompressed_size); *1/ */
	/* debug("< zipfs"); */

	/* debug("> memcpy"); */
	/* cur = 0; */
	/* uint8_t nested_buf[1024] = {0}; */
	/* memcpy(nested_buf, zip.uncompressed, zip.uncompressed_size); */
	/* debug("< memcpy"); */

	/* int i = 0; */
	/* while (cur != zip.uncompressed_size) { */
	/* 	debug("> nested zip"); */
	/* 	zip_t nested_zip; */
	/* 	read_zip(nested_buf, &cur, &nested_zip); */
	/* 	debug("< nested zip"); */
	/* 	debug(nested_zip.file_name); */
	/* 	uint8_t str[256] = {0}; */
	/* 	sprintf(str, "i: %d, cur: %d -- zip.uncompressed_size: %d", i, cur, zip.uncompressed_size); */
	/* 	debug(str); */
	/* 	i++; */
	/* } */

	/* debug_buffer(&zip.file_name, zip.file_name_length); */
	/* printf("%x", 100, 250, NULL, &zip.file_name); */


	/* draw_mandel(); */

	/* end_of_execution(); */
	while(1) {};
}

void test_kernel_printing() {
	for (int i = 0; i <= 59; i++) {
		uint8_t *num_str = malloc(256);
		itoa(i, num_str);
		kprint(num_str);
	}
}
