#include <cpuid.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "memcpy.h"
#include "tinyprintf.h"

#include "fpu.h"
#include "heap.h"
#include "idt.h"
#include "mandel.h"
#include "multiboot.h"
#include "pic.h"
#include "ports.h"
#include "print.h"
#include "serial.h"
#include "string.h"
#include "terminal-font.h"
#include "video.h"

#include "format/zip.h"

#include "rust/floof.h"
#include "zig/hello.h"

void warn_interrupt(uint8_t interrupt_number) {
	error("Interrupt: %d/%x!", interrupt_number, interrupt_number);

	uint8_t  red[4]     = {255, 0, 0, 0xff};
	uint8_t* error_name = malloc(256);
	if (error_name == NULL) {
		error("Could not allocate memory for error name!");
		return;
	}
	num_to_error_name(interrupt_number, error_name);

	uint8_t* tmp = malloc(256);
	if (tmp == NULL) {
		error("Could not allocate memory for tmp!");
		return;
	}
	snprintf(tmp, 256, "Warning! Interrupt occurred: %s [%d/%x]", error_name, interrupt_number, interrupt_number);
	print_box(tmp, LARGE_FONT_CELL_WIDTH, 2, red);
}

void end_of_execution() {
	uint8_t green[4] = {0, 255, 0, 0xff};
	print_box("End of execution.", LARGE_FONT_CELL_WIDTH, 2, green);
}


uint8_t* get_cpu_vendor() {
	uint32_t eax;
	uint32_t ebx;
	uint32_t ecx;
	uint32_t edx;
	uint32_t unused;
	__cpuid(0, eax, ebx, ecx, edx);

	uint8_t* vendor_string = malloc(13);
	vendor_string[0]  = ebx & 0xff;
	vendor_string[1]  = (ebx >> 8)  & 0xff;
	vendor_string[2]  = (ebx >> 16) & 0xff;
	vendor_string[3]  = (ebx >> 24) & 0xff;
	vendor_string[4]  = edx & 0xff;
	vendor_string[5]  = (edx >> 8)  & 0xff;
	vendor_string[6]  = (edx >> 16) & 0xff;
	vendor_string[7]  = (edx >> 24) & 0xff;
	vendor_string[8]  = ecx & 0xff;
	vendor_string[9]  = (ecx >> 8)  & 0xff;
	vendor_string[10] = (ecx >> 16) & 0xff;
	vendor_string[11] = (ecx >> 24) & 0xff;
	vendor_string[12] = 0;

	debug("Highest CPUID leaf: %d", eax);

	return vendor_string;
}

void get_cpu_features() {
	uint32_t eax;
	uint32_t edx;
	uint32_t unused;
	if (__get_cpuid(1, &eax, &unused, &unused, &edx) == false) {
		error("Could not get CPU features!");
		return;
	}

	debug("CPU features: %x", edx);
}

extern void enter_userland(uint8_t* data, uint32_t size);

void main(multiboot_info_t* boot_info) {
	init_serial(SERIAL_COM1_PORT);
	init_serial(SERIAL_COM2_PORT);

	init_printf(NULL, serial_debug_write_byte);

	debug("zig: %d", foo(1));
	debug("rust: %d", bar(2));

	debug("Kernel started");
	// Setup interrupts.
	idt_init();

	uint8_t* vendor = get_cpu_vendor();
	debug("Vendor: %s", vendor);
	get_cpu_features();

	parse_multiboot_header(boot_info);

	// Enable floating point operations.
	enable_fpu();

	ide_dev_t dev = {
		ATA_PRIMARY_BUS,
		ATA_PRIMARY_DRIVE,
		ATA_PRIMARY_IO,
	};
	uint64_t fsbuf_size = 0x801000;
	uint8_t* fsbuf = malloc(fsbuf_size);
	if (fsbuf == NULL) {
		error("Could not allocate memory for file system buffer!");
		return;
	}
	// TODO: implement an actual file system.
	debug("> ATA");
	ata_read(fsbuf, 0, fsbuf_size / 512, &dev);
	debug("< ATA");

	debug("> zipfs");
	uint64_t zipfs_size = peek_zip(fsbuf);
	if (zipfs_size == 0) {
		error("Malformed zipfs! Maybe `fsbuf_size` is too small? Aborting.");
		return;
	}
	if (zipfs_size >= fsbuf_size) {
		error("Unable to read file system: `fsbuf_size` is too small!");
		return;
	}

	zip_fs_t zipfs;
	read_zip(fsbuf, zipfs_size, &zipfs);
	debug("< zipfs");

	debug("File system initialized.");
	for (uint32_t i = 0; i < zipfs.num_files; i++) {
		file_t* file = zipfs.files[i];
		debug(file->name);
		if (streq(file->name, "bg.raw") == false) {
			continue;
		}
		debug("found bg.raw!");
		set_frame(file->data);
	}

	// Linear search for the win!
	for (uint32_t i = 0; i < zipfs.num_files; i++) {
		file_t* file = zipfs.files[i];
		debug(file->name);
		if (streq(file->name, "userland.elf") == false) {
			continue;
		}
		debug("found userland.elf: %d", file->size);

		// Work in progress.
		enter_userland(file->data, file->size);
		break;
	}

	while (1) {
		sleep(10);
	}
}
