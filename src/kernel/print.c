void kprintf(uint32_t x, uint32_t y, uint8_t* color, uint8_t* format, ...) {
	uint8_t* buffer = malloc(256);
	if (buffer == NULL) {
		error("kprintf: malloc failed");
		return;
	}
	va_list args;
	va_start(args, format);
	vsnprintf(buffer, sizeof(buffer), format, args);
	va_end(args);

	draw_string(buffer, x, y, color);
}

void print_box(uint8_t* s, uint32_t x, uint32_t y, uint8_t* color) {
	const uint8_t top_left_corner     = 0xda;
	const uint8_t flat                = 0xc4;
	const uint8_t top_right_corner    = 0xbf;
	const uint8_t pipe                = 0xb3;
	const uint8_t bottom_left_corner  = 0xc0;
	const uint8_t bottom_right_corner = 0xd9;

	uint8_t* tmp = malloc(256);
	if (tmp == NULL) {
		error("malloc failed");
		return;
	}
	uint32_t len = strlen(s) + 2; // +2 for the pipe and the spacing.

	uint32_t xoffset = 0;
	uint32_t yoffset = 0;
	kprintf(x + xoffset, y + yoffset, color, "%c", top_left_corner);
	xoffset += LARGE_FONT_CELL_WIDTH;
	for (uint32_t i = 0; i < len; i++) {
		kprintf(x + xoffset, y + yoffset, color, "%c", flat);
		xoffset += LARGE_FONT_CELL_WIDTH;
	}
	kprintf(x + xoffset, y + yoffset, color, "%c", top_right_corner);

	xoffset = 0;
	// -2 for better spacing (connect the ascii box chars.).
	yoffset += LARGE_FONT_CELL_HEIGHT - 2;
	kprintf(x + xoffset, y + yoffset, color, "%c %s %c", pipe, s, pipe);

	// -2 for better spacing (connect the ascii box chars.).
	yoffset += LARGE_FONT_CELL_HEIGHT - 2;
	kprintf(x + xoffset, y + yoffset, color, "%c", bottom_left_corner);
	xoffset += LARGE_FONT_CELL_WIDTH;
	for (uint32_t i = 0; i < len; i++) {
		kprintf(x + xoffset, y + yoffset, color, "%c", flat);
		xoffset += LARGE_FONT_CELL_WIDTH;
	}
	kprintf(x + xoffset, y + yoffset, color, "%c", bottom_right_corner);
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
		kprintf(0, line_number * LARGE_FONT_CELL_HEIGHT, NULL, "%s", l->line);
	}
	line_number++;
	/* printf("%s", 0, line_number*LARGE_FONT_CELL_HEIGHT, 0, s); */
}
