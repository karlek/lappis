// Parse newline and set cursor to next row.
void kprint(char *string) {}

void kprint_at(char *string, int col, int row) {}

void write_string(int color, const char *string) {
	volatile char *video = (volatile char*)VIDEO_ADDRESS;
	while(*string != 0) {
		*video++ = *string++;
		*video++ = color;
	}
}
