void outb(unsigned short port, uint8_t data) {
	__asm__("out dx, al" : : "a" (data), "d" (port));
}

uint8_t inb(unsigned short port) {
	uint8_t result;
	__asm__("in al, dx" : "=a" (result) : "d" (port));
	return result;
}

uint16_t inw(unsigned short port) {
	uint16_t result;
	__asm__("in ax, dx" : "=a" (result) : "d" (port));
	return result;
}
