void sprintf(uint8_t* out, uint8_t* format, ...) {
	va_list args;
	va_start(args, format);
	uint8_t* str = malloc(256);

	uint32_t offset = 0;
	for (uint8_t* c = format; *c != '\0'; c++) {
		// Skip newline and goto next line & reset x-coordinate.
		if (*c != '%') {
			str[offset++] = *c;
			continue;
		}

		// TODO: It's impossible to print a percentage sign.
		c++;

		switch (*c) {
		case 'c':
			uint8_t carg  = va_arg(args, int);
			str[offset++] = carg;
			break;
		case 's':
			uint8_t* arg = va_arg(args, char*);
			strcat(str, arg);
			offset += strlen(arg);
			break;
		case 'd':
			int64_t  num     = va_arg(args, int);
			uint8_t* num_str = malloc(256);
			itoa(num, num_str);
			strcat(str, num_str);
			offset += strlen(num_str);
			break;
		case 'x':
			int64_t  hnum     = va_arg(args, int);
			uint8_t* hnum_str = malloc(256);
			htox(hnum, hnum_str, true);
			strcat(str, hnum_str);
			offset += strlen(hnum_str);
			break;
		default:
			str[offset++] = '?';
			break;
		}
	}

	va_end(args);
	strcat(out, str);
}

void printf(uint8_t* format, uint32_t x, uint32_t y, uint8_t* color, ...) {
	uint8_t* str = malloc(256);
	va_list  args;
	va_start(args, color);

	uint32_t offset = 0;
	for (uint8_t* c = format; *c != '\0'; c++) {
		// Skip newline and goto next line & reset x-coordinate.
		if (*c == '\n') {
			draw_string(str, x, y, color);

			y += LARGE_FONT_CELL_HEIGHT;
			x = 0;

			for (uint32_t i = 0; i < offset; i++) {
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
			uint8_t carg  = va_arg(args, int);
			str[offset++] = carg;
			break;
		case 's':
			uint8_t* arg = va_arg(args, char*);
			strcat(str, arg);
			offset += strlen(arg);
			break;
		case 'd':
			int64_t  num     = va_arg(args, int);
			uint8_t* num_str = malloc(256);
			itoa(num, num_str);
			strcat(str, num_str);
			offset += strlen(num_str);
			break;
		case 'x':
			int64_t  hnum     = va_arg(args, int);
			uint8_t* hnum_str = malloc(256);
			htox(hnum, hnum_str, true);
			strcat(str, hnum_str);
			offset += strlen(hnum_str);
			break;
		case 'v':
			uint8_t* vnum = va_arg(args, uint8_t*);
			for (uint32_t i = 0; i < 4; i++) {
				if (vnum[i] == 0) {
					break;
				}
				uint8_t* num_str = malloc(256);
				htox(vnum[i], num_str, false);
				strcat(str, num_str);
				offset += strlen(num_str);
			}
			break;
		default:
			str[offset++] = '?';
			break;
		}
	}

	va_end(args);
	draw_string(str, x, y, color);
}

void print_box(uint8_t* s, uint32_t x, uint32_t y, uint8_t* color) {
	const uint8_t top_left_corner     = 0xda;
	const uint8_t flat                = 0xc4;
	const uint8_t top_right_corner    = 0xbf;
	const uint8_t pipe                = 0xb3;
	const uint8_t bottom_left_corner  = 0xc0;
	const uint8_t bottom_right_corner = 0xd9;

	uint8_t* tmp = malloc(256);
	uint32_t len = strlen(s) + 2; // +2 for the pipe and the spacing.

	uint32_t xoffset = 0;
	uint32_t yoffset = 0;
	printf("%c", x + xoffset, y + yoffset, color, top_left_corner);
	xoffset += LARGE_FONT_CELL_WIDTH;
	for (uint32_t i = 0; i < len; i++) {
		printf("%c", x + xoffset, y + yoffset, color, flat);
		xoffset += LARGE_FONT_CELL_WIDTH;
	}
	printf("%c", x + xoffset, y + yoffset, color, top_right_corner);

	xoffset = 0;
	// -2 for better spacing (connect the ascii box chars.).
	yoffset += LARGE_FONT_CELL_HEIGHT - 2;
	printf("%c %s %c", x + xoffset, y + yoffset, color, pipe, s, pipe);

	// -2 for better spacing (connect the ascii box chars.).
	yoffset += LARGE_FONT_CELL_HEIGHT - 2;
	printf("%c", x + xoffset, y + yoffset, color, bottom_left_corner);
	xoffset += LARGE_FONT_CELL_WIDTH;
	for (uint32_t i = 0; i < len; i++) {
		printf("%c", x + xoffset, y + yoffset, color, flat);
		xoffset += LARGE_FONT_CELL_WIDTH;
	}
	printf("%c", x + xoffset, y + yoffset, color, bottom_right_corner);
}

uint32_t line_number = 0;

typedef struct lines {
	char*         line;
	struct lines* next;
} lines_t;

lines_t kernel_lines = {
	.line = NULL,
	.next = NULL,
};
lines_t* current_lines = &kernel_lines;

void kprint(uint8_t* s) {
	lines_t next = {
		.line = s,
		.next = NULL,
	};
	current_lines->next = &next;

	current_lines = &next;
	/* clear_screen(); */

	for (lines_t* l = &kernel_lines; l != NULL; l = l->next) {
		printf("%s", 0, line_number * LARGE_FONT_CELL_HEIGHT, 0, l->line);
	}
	line_number++;
	/* printf("%s", 0, line_number*LARGE_FONT_CELL_HEIGHT, 0, s); */
}
