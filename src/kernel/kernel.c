#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "multiboot.c"

#include "ports.c"
#include "string.c"
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
	uint64_t buf_size = 0xa00000;
	uint8_t *read_buf = malloc(buf_size);
	// TODO: Warn if there's data left on disk, but buf_size is too small.
	// Or even better, only parse the header of the zip file and ascertain
	// whether the size is too small.
	// Or even better, implement an actual file system.
	ata_read(read_buf, 0, buf_size/512, &dev);
	debug("< ATA");

	debug("> first zipfs layer");
	zip_fs_t first_layer;
	read_zip(read_buf, -1, &first_layer);
	debug("< first zipfs layer");

	debug("> inner zipfs layer");
	zip_fs_t zipfs;

	printf("File system initialized.\n", 0, 0, NULL);
	read_zip(first_layer.files[0]->data, first_layer.files[0]->size, &zipfs);
	for (uint32_t i = 0; i < zipfs.num_files; i++) {
		file_t* file = zipfs.files[i];
		debug(file->name);
		if (streq(file->name, "zipfs/bg.raw") == false) {
			continue;
		}
		debug("found bg.raw!");
		for (uint32_t x = 0; x < WIDTH; x++) {
			for (uint32_t y = 0; y < HEIGHT; y++) {
				uint8_t* bg_pixel = &(file->data[(y * WIDTH)*4 + (x*4)]);
				set_pixel(x, y, bg_pixel);
			}
		}
	}
	debug("< inner zipfs layer");

	while(1) {};
}
