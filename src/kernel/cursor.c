#include "ports.c"

#define REG_SCREEN_CTRL 0x3d4
#define REG_SCREEN_DATA 0x3d5

unsigned short get_cursor_pos() {
	/* Requesting high byte */
	outb(REG_SCREEN_CTRL, 14);
	unsigned short position = inb(REG_SCREEN_DATA) << 8;

	/* Requesting low byte */
    outb(REG_SCREEN_CTRL, 15);
    position += inb(REG_SCREEN_DATA);

	return position;
}

void set_cursor_pos(unsigned short offset) {
	outb(REG_SCREEN_CTRL, 14);
	outb(REG_SCREEN_DATA, (unsigned char) (offset >> 8));
	outb(REG_SCREEN_CTRL, 15);
	outb(REG_SCREEN_DATA, (unsigned char) (offset & 0xff));
}

