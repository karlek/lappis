void outb(unsigned short port, unsigned char data) {
	__asm__("out dx, al" : : "a" (data), "d" (port));
}

unsigned char inb(unsigned short port) {
	unsigned char result;
	__asm__("in al, dx" : "=a" (result) : "d" (port));
	return result;
}
