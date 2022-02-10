#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

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

void main() {
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

	/* draw_mandel(); */

	print_box("Press any key:", 0, 0, NULL);
	// Trigger a breakpoint exception.
	/* __asm__ __volatile__("int3"); */

	/* end_of_execution(); */

	while(1) {};
}

