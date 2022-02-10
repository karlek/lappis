// Parse newline and set cursor to next row.
void kprint(char *string) {}

void kprint_at(char *string, int col, int row) {}

void write_string(int color, const char *string) {
	volatile char *video = (volatile char*)VIDEO_ADDRESS;
	while(*string != 0) {
		*video++ = *string++;
		*video++ = color;
	}
}

void sprintf(unsigned char *out, unsigned char *format, ...) {
	va_list args;
	va_start(args, format);
	unsigned char str[256] = {0};

	int offset = 0;
	for(unsigned char* c = format; *c != '\0'; c++) {
		// Skip newline and goto next line & reset x-coordinate.
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
	strcat(out, str);
}

void printf(unsigned char *format, int x, int y, unsigned char *color, ...) {
	unsigned char str[256] = {0};
	va_list args;
	va_start(args, color);

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

void print_box(unsigned char *s, int x, int y, unsigned char *color) {
	const unsigned char top_left_corner = 0xda;
	const unsigned char flat = 0xc4;
	const unsigned char top_right_corner = 0xbf;
	const unsigned char pipe = 0xb3;
	const unsigned char bottom_left_corner = 0xc0;
	const unsigned char bottom_right_corner = 0xd9;

	char tmp[256] = {0};
	int len = strlen(s)+2; // +2 for the pipe and the spacing.

	unsigned int xoffset = 0;
	unsigned int yoffset = 0;
	printf("%c", x+xoffset, y+yoffset, color, top_left_corner);
	xoffset += LARGE_FONT_CELL_WIDTH;
	for (int i = 0; i < len; i++) {
		printf("%c", x+xoffset, y+yoffset, color, flat);
		xoffset += LARGE_FONT_CELL_WIDTH;
	}
	printf("%c", x+xoffset, y+yoffset, color, top_right_corner);

	xoffset = 0;
	yoffset += LARGE_FONT_CELL_HEIGHT-2; // -2 for better spacing (connect the ascii box chars.).
	printf("%c %s %c", x+xoffset, y+yoffset, color, pipe, s, pipe);

	yoffset += LARGE_FONT_CELL_HEIGHT-2; // -2 for better spacing (connect the ascii box chars.).
	printf("%c", x+xoffset, y+yoffset, color, bottom_left_corner);
	xoffset += LARGE_FONT_CELL_WIDTH;
	for (int i = 0; i < len; i++) {
		printf("%c", x+xoffset, y+yoffset, color, flat);
		xoffset += LARGE_FONT_CELL_WIDTH;
	}
	printf("%c", x+xoffset, y+yoffset, color, bottom_right_corner);
}

