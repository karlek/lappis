void write_string(int color, const char *string) {
	volatile char *video = (volatile char*)0xB8000;
	while(*string != 0) {
		*video++ = *string++;
		*video++ = color;
	}
}

void main() {
	const char *str = "Hello, world!";
	write_string(0xf0, str);
	while(1);
}

