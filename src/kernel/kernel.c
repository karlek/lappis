#include <stdint.h>
#include <stdbool.h>

#include "idt.c"
#include "fpu.c"
#include "mandel.c"

void main() {
	// Setup interrupts.
	idt_init();

	// Enable floating point operations.
	enable_fpu();

	// Draw the mandelbrot set.
	draw_mandel();
}
