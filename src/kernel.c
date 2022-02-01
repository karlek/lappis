#define REG_SCREEN_CTRL 0x3D4
#define REG_SCREEN_DATA 0x3D5
#define MAX_COLS 80
#define MAX_ROWS 25
#define VIDEO_ADDRESS 0xb8000

void write_string(int color, const char *string) {
	volatile char *video = (volatile char*)VIDEO_ADDRESS;
	while(*string != 0) {
		*video++ = *string++;
		*video++ = color;
	}
}

void out_port(unsigned short port, unsigned char data) {
	__asm__("out dx, al" : : "a" (data), "d" (port));
}

unsigned char in_port(unsigned short port) {
	unsigned char result;
	__asm__("in al, dx" : "=a" (result) : "d" (port));
	return result;
}

unsigned short get_cursor_pos() {
	/* Requesting high byte */
	out_port(REG_SCREEN_CTRL, 14);
	unsigned short position = in_port(REG_SCREEN_DATA) << 8;

	/* Requesting low byte */
    out_port(REG_SCREEN_CTRL, 15);
    position += in_port(REG_SCREEN_DATA);

	return position;
}

void set_cursor_pos(unsigned short offset) {
	out_port(REG_SCREEN_CTRL, 14);
	out_port(REG_SCREEN_DATA, (unsigned char) (offset >> 8));
	out_port(REG_SCREEN_CTRL, 15);
	out_port(REG_SCREEN_DATA, (unsigned char) (offset & 0xff));
}

void main() {
	const char *str = "Hello, world!";
	write_string(0xf0, str);

	get_cursor_pos();
	set_cursor_pos(10);
	get_cursor_pos();
}
