
int tuturu = 0;
int s_tat_raw = 0;
int x_rel_raw = 0;
int y_rel_raw = 0;

extern void mouse_handler() {
	PIC_sendEOI(44);

	for (;;) {
		uint8_t st = inb(CMD_PORT);
		if ((st&0x01) == 0) {
			break;
		}
		uint8_t x = inb(DATA_PORT);
		handle(x);
	}

	printf("break!\n", 0, 400, NULL);
}

void handle(uint8_t x) {
	switch (tuturu) {
	case 0:
		s_tat_raw = x;
		break;
	case 1:
		x_rel_raw = x;
		break;
	case 2:
		y_rel_raw = x;
		break;
	}

	/* asm("cli; hlt"); */
	printf("tuturu: %d\n", 0, 300, NULL, tuturu);
	tuturu++;
	/* tuturu = (tuturu + 1) % 3; */
}
