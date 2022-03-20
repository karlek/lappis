static int32_t mouse_count = 0;

static int32_t stat_raw = 0;
static int32_t xrel_raw = 0;
static int32_t yrel_raw = 0;

static int32_t mouse_cursor_x = 0;
static int32_t mouse_cursor_y = 0;

void draw_cursor() {
	draw_char('\x03', mouse_cursor_x, mouse_cursor_y, NULL);
}

void handle(uint8_t x) {
	switch (mouse_count) {
	case 0:
		stat_raw = x;
		break;
	case 1:
		xrel_raw = x;
		break;
	case 2:
		yrel_raw = x;
		// We have a complete packet.

		bool y_overflow    = (stat_raw & 0x80) != 0;
		bool x_overflow    = (stat_raw & 0x40) != 0;
		bool y_signed      = (stat_raw & 0x20) != 0;
		bool x_signed      = (stat_raw & 0x10) != 0;
		bool always_one    = (stat_raw & 0x08) != 0;
		bool button_middle = (stat_raw & 0x04) != 0;
		bool button_right  = (stat_raw & 0x02) != 0;
		bool button_left   = (stat_raw & 0x01) != 0;

		kprintf(0,
		       280, NULL, "flag: yo xo ys xs ao bm br bl                             ");
		kprintf( 0, 300, NULL, "bool: %d  %d  %d  %d  %d  %d  %d  %d                            ",y_overflow, x_overflow, y_signed, x_signed,
			always_one, button_middle, button_right, button_left);
		kprintf(0, 320,
		       NULL, "poss: %d  %d  %d  %d                              ", mouse_cursor_x, mouse_cursor_y, xrel_raw, yrel_raw);

		mouse_cursor_x += (int8_t)xrel_raw;
		mouse_cursor_y -= (int8_t)yrel_raw;

		if (mouse_cursor_x <= 0) {
			mouse_cursor_x = 0;
		}
		if (mouse_cursor_y <= 0) {
			mouse_cursor_y = 0;
		}

		if (mouse_cursor_x >= WIDTH) {
			mouse_cursor_x = WIDTH - 1;
		}
		if (mouse_cursor_y >= HEIGHT) {
			mouse_cursor_y = HEIGHT - 1;
		}

		draw_cursor();

		break;
	}

	mouse_count = (mouse_count + 1) % 3;
}

extern void mouse_handler() {
	PIC_sendEOI(44);

	for (;;) {
		uint8_t st = inb(CMD_PORT);
		if ((st & 0x01) == 0) {
			break;
		}
		uint8_t x = inb(DATA_PORT);
		handle(x);
	}
}

void enable_mouse() {
	debug("Enabling PS/2 mouse.");
	ps2_write(CMD_PORT, 0xa8);

	// Get status byte.
	ps2_write(CMD_PORT, 0x20);

	uint8_t status = ps2_read(DATA_PORT);
	status |= 0x2;
	status &= 0xdf;

	// Set status byte.
	ps2_write(CMD_PORT, 0x60);
	ps2_write(DATA_PORT, status);

	// Communicate with mouse.
	ps2_write(CMD_PORT, 0xD4);
	// Set mouse defaults.
	ps2_write(DATA_PORT, 0xf6);

	uint8_t ret = ps2_read(DATA_PORT);
	if (ret != 0xfa) {
		error("Failed to set mouse defaults.");
		return;
	}

	// Communicate with mouse.
	ps2_write(CMD_PORT, 0xD4);
	// Enable mouse data reporting.
	ps2_write(DATA_PORT, 0xf4);
	ret = ps2_read(DATA_PORT);
	if (ret != 0xfa) {
		error("Failed to enable mouse data reporting.");
		return;
	}

	debug("PS/2 mouse enabled.");
}
