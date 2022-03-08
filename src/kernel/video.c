#define FRAME_BUFFER 0x4800000
#define WIDTH        1280
#define HEIGHT       1024

void set_pixel(uint32_t x, uint32_t y, uint8_t color[4]) {
	volatile uint8_t* fb = (volatile uint8_t*)FRAME_BUFFER;

	// Colors are written in little endian order.
	// Red
	fb[(y * WIDTH + x) * 4 + 2] = color[0];
	// Green
	fb[(y * WIDTH + x) * 4 + 1] = color[1];
	// Blue
	fb[(y * WIDTH + x) * 4 + 0] = color[2];
	// Alpha
	fb[(y * WIDTH + x) * 4 + 3] = color[3];
}

void draw_char(uint8_t c, uint32_t x, uint32_t y, uint8_t* color) {
	uint8_t black[4] = {0, 0, 0, 0xff};
	uint8_t white[4] = {255, 255, 255, 0xff};
	if (color == NULL) {
		color = white;
	}

	uint16_t* bitmap = large_font[c];
	// The first & last row bitmap is always empty.
	for (uint32_t i = 1; i < LARGE_FONT_CELL_HEIGHT; i++) {
		uint8_t row_bitmap = bitmap[i];
		for (uint32_t j = 0; j < LARGE_FONT_CELL_WIDTH; j++) {
			if (row_bitmap & (1 << j)) {
				// Bitmap is set from left to right, so we need to flip it.
				set_pixel(x + (LARGE_FONT_CELL_WIDTH - j), y + i, color);
			} else {
				set_pixel(x + (LARGE_FONT_CELL_WIDTH - j), y + i, black);
			}
		}
	}
}

void draw_string(uint8_t* str, uint32_t x, uint32_t y, uint8_t* color) {
	const uint32_t letter_spacing = 0;

	for (uint32_t i = 0; str[i] != '\0'; i++) {
		uint8_t c = str[i];
		draw_char(c, x, y, color);
		x += LARGE_FONT_CELL_WIDTH;
		if (c < 169 || c > 223) {
			// Hack lol.
			// Don't use letter spacing for boxing characters.
			x += letter_spacing;
		}
	}
}

void clear_screen() {
	uint8_t black[4] = {0, 0, 0, 0xff};
	for (uint32_t y = 0; y < HEIGHT; y++) {
		for (uint32_t x = 0; x < WIDTH; x++) {
			set_pixel(x, y, black);
		}
	}
}
