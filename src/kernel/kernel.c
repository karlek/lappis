#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "idt.c"
#include "fpu.c"
#include "mandel.c"
#include "terminal-font.h"

void itoa(int num, char *str) {
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
	char tmp[10] = {0};
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
void htox(int num, char *str) {
	int offset = 0;
	char tmp[4] = {0};
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
		// TODO: Support for negative numbers.
		tmp[offset++] = '?';
	}
	*(str++) = '0';
	*(str++) = 'x';
	while (offset > 0) {
		*(str++) = tmp[--offset];
	}
	str[offset] = '\0';
}

// inb4 vulns
void strcat(char *dest, const char *src) {
	while (*dest) {
		dest++;
	}
	while (*src) {
		*dest++ = *src++;
	}
	*dest = '\0';
}

void draw_char(char c, int x, int y, unsigned char *color) {
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
				set_pixel(x+(LARGE_FONT_CELL_WIDTH-j), y+i, black);
			}
		}
	}
}

void draw_string(char *str, int x, int y, unsigned char *color) {
	const int letter_spacing = 1;

	for (int i = 0; str[i] != '\0'; i++) {
		draw_char(str[i], x, y, color);
		x += LARGE_FONT_CELL_WIDTH+letter_spacing;
	}
}

int strlen(char * s) {
	int len = 0;
	while (*s++) {
		len++;
	}
	return len;
}

void printf(char *format, int x, int y, unsigned char *color, ...) {
	va_list args;
	va_start(args, color);
	char str[256] = {0};

	int offset = 0;
	for(char* c = format; *c != '\0'; c++) {
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
			case 's':
				char * arg = va_arg(args, char*);
				strcat(str, arg);
				offset += strlen(arg);
				break;
			case 'd':
				int num = va_arg(args, int);
				char num_str[256] = {0};
				itoa(num, num_str);
				strcat(str, num_str);
				offset += strlen(num_str);
				break;
			case 'x':
				int hnum = va_arg(args, int);
				char hnum_str[256] = {0};
				htox(hnum, hnum_str);
				strcat(str, hnum_str);
				offset += strlen(hnum_str);
			default:
				str[offset++] = '?';
				break;
		}
	}

    va_end(args);
	draw_string(str, x, y, color);
}

void warn_interrupt(int interrupt_number, int error_code) {
	unsigned char red[3] = {255, 0, 0};
	printf("Warning: Interrupt occured: %d (%x)\n", 0, 0, red, interrupt_number, error_code);
}

void main() {
	// Setup interrupts.
	idt_init();

	// Enable floating point operations.
	enable_fpu();

	printf("Keep it %s\n", 0, 0, NULL, "lapsang \x03");
	printf("%d == %d\n", 0, LARGE_FONT_CELL_HEIGHT, NULL, (-1 << 31), -2147483648);
	printf("%d == %d\n", 0, LARGE_FONT_CELL_HEIGHT*2, NULL, -2147483648+1, -2147483647);
}

