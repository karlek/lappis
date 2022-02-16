#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "multiboot2.h"

#include "string.c"
#include "ports.c"
#include "terminal-font.h"
#include "video.c"
#include "mandel.c"
#include "print.c"
#include "pic.c"
#include "idt.c"
#include "fpu.c"

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

/* struct multiboot_tag { */
/*     uint32_t type; */
/*     uint32_t size; */
/* }; */

struct multiboot_info {
    uint32_t total_size;
    uint32_t reserved;
    struct multiboot_tag tags[0];
};

unsigned char* get_tag_name(int tag_type) {
	switch (tag_type) {
		case 0: {return "MULTIBOOT_TAG_TYPE_END";}
		case 1: {return "MULTIBOOT_TAG_TYPE_CMDLINE";}
		case 2: {return "MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME";}
		case 3: {return "MULTIBOOT_TAG_TYPE_MODULE";}
		case 4: {return "MULTIBOOT_TAG_TYPE_BASIC_MEMINFO";}
		case 5: {return "MULTIBOOT_TAG_TYPE_BOOTDEV";}
		case 6: {return "MULTIBOOT_TAG_TYPE_MMAP";}
		case 7: {return "MULTIBOOT_TAG_TYPE_VBE";}
		case 8: {return "MULTIBOOT_TAG_TYPE_FRAMEBUFFER";}
		case 9: {return "MULTIBOOT_TAG_TYPE_ELF_SECTIONS";}
		case 10: {return "MULTIBOOT_TAG_TYPE_APM";}
		case 11: {return "MULTIBOOT_TAG_TYPE_EFI32";}
		case 12: {return "MULTIBOOT_TAG_TYPE_EFI64";}
		case 13: {return "MULTIBOOT_TAG_TYPE_SMBIOS";}
		case 14: {return "MULTIBOOT_TAG_TYPE_ACPI_OLD";}
		case 15: {return "MULTIBOOT_TAG_TYPE_ACPI_NEW";}
		case 16: {return "MULTIBOOT_TAG_TYPE_NETWORK";}
		case 17: {return "MULTIBOOT_TAG_TYPE_EFI_MMAP";}
		case 18: {return "MULTIBOOT_TAG_TYPE_EFI_BS";}
		case 19: {return "MULTIBOOT_TAG_TYPE_EFI32_IH";}
		case 20: {return "MULTIBOOT_TAG_TYPE_EFI64_IH";}
		case 21: {return "MULTIBOOT_TAG_TYPE_LOAD_BASE_ADDR";}
		default:
			return "Unknown";
	}
}

void main(struct multiboot_info* boot_info) {
	// Setup interrupts.
	idt_init();

	// Enable floating point operations.
	enable_fpu();

	// Hardware interrupts / keyboard.
	//
	// draw_mandel takes a while, so we'll surely trigger a clock interrupt
	// during it's execution.
	//
	// So we need to remap the PIC to not collide with the standard exceptions.
	PIC_remap(0x20, 0x28);

	int i = 0;
	struct multiboot_tag *tag = boot_info->tags;
	while (tag->type != 0) {
		switch (tag->type) {
			default:
				unsigned int next = ((tag->size+8) / 8);
				printf("Skipping: %s\n", 300, 300+i*LARGE_FONT_CELL_HEIGHT, NULL, get_tag_name(tag->type));
				tag += next;
		}
		i++;
	}

	/* draw_mandel(); */

	print_box("Press any key:", 0, 0, NULL);
	// Trigger a breakpoint exception.
	/* __asm__ __volatile__("int3"); */

	/* end_of_execution(); */

	while(1) {};
}

