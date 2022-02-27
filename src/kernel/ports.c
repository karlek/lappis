void outb(uint16_t port, uint8_t data) {
	__asm__("out dx, al" : : "a" (data), "d" (port));
}

uint8_t inb(uint16_t port) {
	uint8_t result;
	__asm__("in al, dx" : "=a" (result) : "d" (port));
	return result;
}

uint16_t inw(uint16_t port) {
	uint16_t result;
	__asm__("in ax, dx" : "=a" (result) : "d" (port));
	return result;
}
