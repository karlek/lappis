#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "idt.c"
#include "fpu.c"
#include "mandel.c"
#include "terminal-font.h"

// inb4 vulns
void strcat(unsigned char *dest, const unsigned char *src) {
	while (*dest) {
		dest++;
	}
	while (*src) {
		*dest++ = *src++;
	}
	*dest = '\0';
}

void itoa(int num, unsigned char *str) {
	bool is_negative = false;
	if (num < 0) {
		is_negative = true;
		num = -num;
	}

	// Handle MinInt case.
	if (num == (-1 << 31)) {
		strcat(str, "-2147483648");
		return;
	}

	if (is_negative) {
		str[0] = '-';
		str++;
	}

	int offset = 0;
	unsigned char tmp[10] = {0};
	while (num > 0) {
		tmp[offset++] = (num % 10) + '0';
		num /= 10;
	}
	while (offset > 0) {
		*(str++) = tmp[--offset];
	}
	str[offset] = '\0';
}

// TODO: This is pretty wonky.
void htox(unsigned int num, unsigned char *str) {
	int offset = 0;
	unsigned char tmp[8] = {0};
	if (num > 0) {
		while (num > 0) {
			uint8_t hdigit = (num % 16);
			if (hdigit < 10) {
				tmp[offset++] = hdigit + '0';
			} else {
				tmp[offset++] = hdigit - 10 + 'a';
			}
			num /= 16;
		}
	} else {
		tmp[offset++] = '0';
	}

	*(str++) = '0';
	*(str++) = 'x';
	while (offset > 0) {
		*(str++) = tmp[--offset];
	}
	str[offset] = '\0';
}

void draw_char(unsigned char c, int x, int y, unsigned char *color) {
	unsigned char black[3] = {0, 0, 0};
	unsigned char white[3] = {255, 255, 255};
	if (color == NULL) {
		color = white;
	}

	uint16_t *bitmap = large_font[c];
	for (int i = 0; i <= LARGE_FONT_CELL_HEIGHT; i++) {
		uint8_t row_bitmap = bitmap[i];
		for (int j = 0; j <= LARGE_FONT_CELL_WIDTH; j++) {
			if (row_bitmap & (1 << j)) {
				// Bitmap is set from left to right, so we need to flip it.
				set_pixel(x+(LARGE_FONT_CELL_WIDTH-j), y+i, color);
			} else {
				/* set_pixel(x+(LARGE_FONT_CELL_WIDTH-j), y+i, black); */
			}
		}
	}
}

void draw_string(unsigned char *str, int x, int y, unsigned char *color) {
	const int letter_spacing = 0;

	for (int i = 0; str[i] != '\0'; i++) {
		unsigned char c = str[i];
		draw_char(c, x, y, color);
		x += LARGE_FONT_CELL_WIDTH;
		if (c < 169 || c > 223) {
			// Hack lol.
			// Don't use letter spacing for boxing characters.
			x += letter_spacing;
		}
	}
}

int strlen(unsigned char * s) {
	int len = 0;
	while (*s++) {
		len++;
	}
	return len;
}

void printf(unsigned char *format, int x, int y, unsigned char *color, ...) {
	va_list args;
	va_start(args, color);
	unsigned char str[256] = {0};

	int offset = 0;
	for(unsigned char* c = format; *c != '\0'; c++) {
		// Skip newline and goto next line & reset x-coordinate.
		if (*c == '\n') {
			draw_string(str, x, y, color);

			y += LARGE_FONT_CELL_HEIGHT;
			x = 0;

			for (int i = 0; i < offset; i++) {
				str[i] = '\0';
			}
			offset = 0;
			continue;
		}
		if (*c != '%') {
			str[offset++] = *c;
			continue;
		}

		// TODO: It's impossible to print a percentage sign.
		c++;

		switch (*c) {
			case 'c':
				unsigned char carg = va_arg(args, int);
				str[offset++] = carg;
				break;
			case 's':
				unsigned char * arg = va_arg(args, char*);
				strcat(str, arg);
				offset += strlen(arg);
				break;
			case 'd':
				int num = va_arg(args, int);
				unsigned char num_str[256] = {0};
				itoa(num, num_str);
				strcat(str, num_str);
				offset += strlen(num_str);
				break;
			case 'x':
				unsigned int hnum = va_arg(args, int);
				unsigned char hnum_str[256] = {0};
				htox(hnum, hnum_str);
				strcat(str, hnum_str);
				offset += strlen(hnum_str);
				break;
			default:
				str[offset++] = '?';
				break;
		}
	}

    va_end(args);
	draw_string(str, x, y, color);
}

void num_to_error_name(int interrupt_number, unsigned char *error_name) {
	switch (interrupt_number) {
		case 0:
			strcat(error_name, "Divide Error");
			break;
		case 1:
			strcat(error_name, "Debug");
			break;
		case 2:
			strcat(error_name, "NMI Interrupt");
			break;
		case 3:
			strcat(error_name, "Breakpoint");
			break;
		case 4:
			strcat(error_name, "Overflow");
			break;
		case 5:
			strcat(error_name, "BOUND Range Exceeded");
			break;
		case 6:
			strcat(error_name, "Invalid Opcode");
			break;
		case 7:
			strcat(error_name, "Device Not Available");
			break;
		case 8:
			strcat(error_name, "Double Fault");
			break;
		case 9:
			strcat(error_name, "Coprocessor Segment Overrun");
			break;
		case 10:
			strcat(error_name, "Invalid TSS");
			break;
		case 11:
			strcat(error_name, "Segment Not Present");
			break;
		case 12:
			strcat(error_name, "Stack-Segment Fault");
			break;
		case 13:
			strcat(error_name, "General Protection Fault");
			break;
		case 14:
			strcat(error_name, "Page Fault");
			break;
		case 15:
			strcat(error_name, "Reserved");
			break;
		case 16:
			strcat(error_name, "x87 FPU Floating-Point Error");
			break;
		case 17:
			strcat(error_name, "Alignment Check");
			break;
		case 18:
			strcat(error_name, "Machine-Check");
			break;
		case 19:
			strcat(error_name, "SIMD Floating-Point Exception");
			break;
		case 20:
			strcat(error_name, "Virtualization Exception");
			break;
		case 21:
			strcat(error_name, "Reserved");
			break;
		case 22:
			strcat(error_name, "Reserved");
			break;
		case 23:
			strcat(error_name, "Reserved");
			break;
		case 24:
			strcat(error_name, "Reserved");
			break;
		case 25:
			strcat(error_name, "Reserved");
			break;
		case 26:
			strcat(error_name, "Reserved");
			break;
		case 27:
			strcat(error_name, "Reserved");
			break;
		case 28:
			strcat(error_name, "Hypervisor Injection Exception");
			break;
		case 29:
			strcat(error_name, "VMM Communication Exception");
			break;
		case 30:
			strcat(error_name, "Security Exception");
			break;
		case 31:
			strcat(error_name, "Reserved");
			break;
		default:
			strcat(error_name, "Unknown interrupt");
			break;
	}
}

void warn_interrupt(int interrupt_number) {
	unsigned char red[3] = {255, 0, 0};
	unsigned char error_name[256] = {0};
	num_to_error_name(interrupt_number, error_name);

	// TODO: Make this a function: box(unsigned char * str, int x, int y, unsigned char * color)
	int i = 0;
	printf("\xda", 0, 2, red);
	for (i = 1; i < 60; i++) {
		printf("\xc4", LARGE_FONT_CELL_WIDTH*i, 2, red);
	}
	printf("\xbf", LARGE_FONT_CELL_WIDTH*i, 2, red);
	// TODO: Refactor `printf` to `sprintf` in order to get `strlen` here.
	printf("\xb3      Warning! Interrupt occurred: %s [%d/%x]      \xb3", 0, LARGE_FONT_CELL_HEIGHT, red, error_name, interrupt_number, interrupt_number);
	printf("\xc0", 0, LARGE_FONT_CELL_HEIGHT*2-2, red);
	for (i = 1; i < 60; i++) {
		printf("\xc4", LARGE_FONT_CELL_WIDTH*i, LARGE_FONT_CELL_HEIGHT*2-2, red);
	}
	printf("\xd9", LARGE_FONT_CELL_WIDTH*i, LARGE_FONT_CELL_HEIGHT*2-2, red);
}

void end_of_execution() {
	unsigned char green[3] = {0, 255, 0};
	printf("End of execution\n", 0, 0, green);
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
	/* PIC_remap(0x20, 0x28); */
	//
	// - Don't forget to uncomment `sti` in `idt_init()`.
	// - Also, don't forget to increase the number of vectors handled and bump
	//   the number of stubs in `idt.asm`.
	draw_mandel();

	// Trigger a breakpoint exception.
	__asm__ __volatile__("int3");

	end_of_execution();
}

