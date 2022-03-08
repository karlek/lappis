#define CMD_PORT  0x64
#define DATA_PORT 0x60

bool ps2_wait_write() {
	uint32_t timer = 500;

	while ((inb(0x64) & 2) && timer-- > 0) {}

	return timer != 0;
}

bool ps2_wait_read() {
	uint32_t timer = 500;

	while (!(inb(0x64) & 1) && timer-- >= 0) {}

	return timer != 0;
}

uint8_t ps2_read(uint32_t port) {
	if (ps2_wait_read()) {
		return inb(port);
	}

	printf("ps2_read fail\n", 0, 400, NULL);

	return -1;
}

bool ps2_write(uint32_t port, uint8_t b) {
	if (ps2_wait_write()) {
		outb(port, b);
		return true;
	}

	printf("ps2_write fail\n", 0, 500, NULL);

	return false;
}
