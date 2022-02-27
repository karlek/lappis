#define SERIAL_COM1_PORT 0x3F8
#define SERIAL_COM2_PORT 0x2F8

static int init_serial(int port) {
	outb(port + 1, 0x00);    // Disable all interrupts
	outb(port + 3, 0x80);    // Enable DLAB (set baud rate divisor)
	outb(port + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
	outb(port + 1, 0x00);    //                  (hi byte)
	outb(port + 3, 0x03);    // 8 bits, no parity, one stop bit
	outb(port + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
	outb(port + 4, 0x0B);    // IRQs enabled, RTS/DSR set
	outb(port + 4, 0x1E);    // Set in loopback mode, test the serial chip
	outb(port + 0, 0xAE);    // Test serial chip (send byte 0xAE and check if serial returns same byte)

	// Check if serial is faulty (i.e: not same byte as sent)
	if(inb(port + 0) != 0xAE) {
		return 1;
	}

	// If serial is not faulty set it in normal operation mode
	// (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
	outb(port + 4, 0x0F);
	return 0;
}

bool is_transmit_empty(int port) {
	return inb(port + 5) & 0x20 == 1;
}

void serial_write_byte(int port, uint8_t a) {
	while (is_transmit_empty(port));

	outb(port, a);
}

void serial_write_string(int port, char *string) {
	while (*string) {
		serial_write_byte(port, *string);
		string++;
	}
}

void debug(char *string) {
	serial_write_string(SERIAL_COM1_PORT, "\033[32;1;1m[DEBUG]\033[0m ");
	serial_write_string(SERIAL_COM1_PORT, string);
	serial_write_string(SERIAL_COM1_PORT, "\n");
}

void error(char *string) {
	serial_write_string(SERIAL_COM1_PORT, "\033[35;1;1m[DEBUG]\033[0m ");
	serial_write_string(SERIAL_COM1_PORT, string);
	serial_write_string(SERIAL_COM1_PORT, "\n");
}

void debug_buffer(uint8_t *buffer, int size) {
	for (int i = 0; i < size; i++) {
		serial_write_byte(SERIAL_COM2_PORT, buffer[i]);
	}
}
