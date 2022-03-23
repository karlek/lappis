#include "ps2.h"

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

	error("ps2_read: fail");

	return -1;
}

bool ps2_write(uint32_t port, uint8_t b) {
	if (ps2_wait_write()) {
		outb(port, b);
		return true;
	}

	error("ps2_write: fail");

	return false;
}
