#define MAX_COLS 80
#define MAX_ROWS 25
#define VIDEO_ADDRESS 0xb8000
#define FRAME_BUFFER 0x8000000
#define WIDTH 1280
#define HEIGHT 1024

void clear_screen() {
	for (unsigned short i = 0; i < MAX_ROWS * MAX_COLS; i++) {
		*((volatile char*) VIDEO_ADDRESS + i*2) = 0;
		*((volatile char*) VIDEO_ADDRESS + i*2+1) = 0;
	}
}

void set_pixel(unsigned int x, unsigned int y, unsigned char color[3]) {
	volatile unsigned char* fb = (volatile unsigned char*)FRAME_BUFFER;

	// Colors are written in little endian order.
	// Red
	fb[(y * WIDTH + x)*3 + 2] = color[0];
	// Green
	fb[(y * WIDTH + x)*3 + 1] = color[1];
	// Blue
	fb[(y * WIDTH + x)*3 + 0] = color[2];
}
