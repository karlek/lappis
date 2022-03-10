#define SERIAL_COM1_PORT 0x3F8
#define SERIAL_COM2_PORT 0x2F8

#define debug(...)  debug_context(__FILE__, __func__, __LINE__, __VA_ARGS__)
#define error(...)  error_context(__FILE__, __func__, __LINE__, __VA_ARGS__)

static bool init_serial(uint16_t port) {
	outb(port + 1, 0x00); // Disable all interrupts
	outb(port + 3, 0x80); // Enable DLAB (set baud rate divisor)
	outb(port + 0, 0x03); // Set divisor to 3 (lo byte) 38400 baud
	outb(port + 1, 0x00); //                  (hi byte)
	outb(port + 3, 0x03); // 8 bits, no parity, one stop bit
	outb(port + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
	outb(port + 4, 0x0B); // IRQs enabled, RTS/DSR set
	outb(port + 4, 0x1E); // Set in loopback mode, test the serial chip
	outb(port + 0, 0xAE); // Test serial chip (send byte 0xAE and check if
	                      // serial returns same byte)

	// Check if serial is faulty (i.e: not same byte as sent)
	if (inb(port + 0) != 0xAE) {
		return false;
	}

	// If serial is not faulty set it in normal operation mode
	// (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
	outb(port + 4, 0x0F);
	return true;
}

bool is_transmit_empty(uint16_t port) {
	return (inb(port + 5) & 0x20) == 1;
}

void serial_write_byte(uint16_t port, uint8_t a) {
	while (is_transmit_empty(port)) {}

	outb(port, a);
}

// Unfortunately, the signature must (void* p, char c) to be compatible with
// tinyprintf.
void serial_debug_write_byte(void* p, char c) {
	serial_write_byte(SERIAL_COM1_PORT, (uint8_t)c);
}

void serial_write_string(uint16_t port, uint8_t* string) {
	while (*string) {
		serial_write_byte(port, *string);
		string++;
	}
}

void debug_context(uint8_t* filename, const uint8_t* func_name, uint32_t linenr, uint8_t *format, ...) {
	uint8_t buffer[256];
	va_list args;
	va_start(args, format);
	tfp_vsnprintf(buffer, sizeof(buffer), format, args);
	va_end(args);

	uint8_t s_linenr[10] = {0};
	itoa(linenr, s_linenr);

	// TODO: Shitty basename.
	filename += strrchr(filename, '/')+1;

	serial_write_string(SERIAL_COM1_PORT, "\033[32;1;1m[DEBUG]\033[0m ");
	serial_write_string(SERIAL_COM1_PORT, "\033[34m");
	serial_write_string(SERIAL_COM1_PORT, filename);
	serial_write_string(SERIAL_COM1_PORT, "\033[0m");
	serial_write_string(SERIAL_COM1_PORT, ":");
	serial_write_string(SERIAL_COM1_PORT, "\033[35m");
	serial_write_string(SERIAL_COM1_PORT, (uint8_t*)func_name);
	serial_write_string(SERIAL_COM1_PORT, "\033[0m");
	serial_write_string(SERIAL_COM1_PORT, ":");
	serial_write_string(SERIAL_COM1_PORT, "\033[37m");
	serial_write_string(SERIAL_COM1_PORT, s_linenr);
	serial_write_string(SERIAL_COM1_PORT, "\033[0m");
	serial_write_string(SERIAL_COM1_PORT, " ");
	serial_write_string(SERIAL_COM1_PORT, buffer);
	serial_write_string(SERIAL_COM1_PORT, "\n");
}

void error_context(uint8_t* filename, const uint8_t* func_name, uint32_t linenr, uint8_t* format, ...) {
	uint8_t buffer[256];
	va_list args;
	va_start(args, format);
	vsnprintf(buffer, sizeof(buffer), format, args);
	va_end(args);

	uint8_t s_linenr[10] = {0};
	itoa(linenr, s_linenr);

	// TODO: Shitty basename.
	filename += strrchr(filename, '/')+1;

	serial_write_string(SERIAL_COM1_PORT, "\033[35;1;1m[ERROR]\033[0m ");
	serial_write_string(SERIAL_COM1_PORT, "\033[34m");
	serial_write_string(SERIAL_COM1_PORT, filename);
	serial_write_string(SERIAL_COM1_PORT, "\033[0m");
	serial_write_string(SERIAL_COM1_PORT, ":");
	serial_write_string(SERIAL_COM1_PORT, "\033[35m");
	serial_write_string(SERIAL_COM1_PORT, (uint8_t*)func_name);
	serial_write_string(SERIAL_COM1_PORT, "\033[0m");
	serial_write_string(SERIAL_COM1_PORT, ":");
	serial_write_string(SERIAL_COM1_PORT, "\033[37m");
	serial_write_string(SERIAL_COM1_PORT, s_linenr);
	serial_write_string(SERIAL_COM1_PORT, "\033[0m");
	serial_write_string(SERIAL_COM1_PORT, " ");
	serial_write_string(SERIAL_COM1_PORT, buffer);
	serial_write_string(SERIAL_COM1_PORT, "\n");
}

void debug_buffer(uint8_t* buffer, uint64_t size) {
	for (uint64_t i = 0; i < size; i++) {
		serial_write_byte(SERIAL_COM2_PORT, buffer[i]);
	}
}
