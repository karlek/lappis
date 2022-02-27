#define FRAME_BUFFER 0x8000000
#define WIDTH 1280
#define HEIGHT 1024

void set_pixel(unsigned int x, unsigned int y, unsigned char color[4]) {
	volatile unsigned char* fb = (volatile unsigned char*)FRAME_BUFFER;

	// Colors are written in little endian order.
	// Red
	fb[(y * WIDTH + x)*4 + 2] = color[0];
	// Green
	fb[(y * WIDTH + x)*4 + 1] = color[1];
	// Blue
	fb[(y * WIDTH + x)*4 + 0] = color[2];
	// Alpha
	fb[(y * WIDTH + x)*4 + 3] = color[3];
}

void draw_char(unsigned char c, int x, int y, unsigned char *color) {
	unsigned char black[4] = {0, 0, 0, 0xff};
	unsigned char white[4] = {255, 255, 255, 0xff};
	if (color == NULL) {
		color = white;
	}

	uint16_t *bitmap = large_font[c];
	// The first & last row bitmap is always empty.
	for (int i = 1; i < LARGE_FONT_CELL_HEIGHT; i++) {
		uint8_t row_bitmap = bitmap[i];
		for (int j = 0; j < LARGE_FONT_CELL_WIDTH; j++) {
			if (row_bitmap & (1 << j)) {
				// Bitmap is set from left to right, so we need to flip it.
				set_pixel(x+(LARGE_FONT_CELL_WIDTH-j), y+i, color);
			} else {
				set_pixel(x+(LARGE_FONT_CELL_WIDTH-j), y+i, black);
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

void clear_screen() {
	unsigned char black[4] = {0, 0, 0, 0xff};
	for (int y = 0; y < HEIGHT; y++) {
		for(int x = 0; x < WIDTH; x++) {
			set_pixel(x, y, black);
		}
	}
}
