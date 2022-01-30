// Note: this example will always write to the top line of the screen.
/* void write_string( int color, const char *string ) */
/* { */
/*     volatile char *video = (volatile char*)0xB8000; */
/*     while( *string != 0 ) */
/*     { */
/* 		*video++ = *string++; */
/*         /1* *video++ = *string++; *1/ */
/*         /1* *video++ = color; *1/ */
/*     } */
/* } */

void main() {
	/* *((int*)0xb8000)=0x07690748; */
	const char *str = "Hello, world!";
	/* write_string(0x27, str); */
	volatile char *video = (volatile char*)0xB8000;
	for (int i = 0; i < 19; i++) {
		*video = str[i];
		video++;
		*video = 0xf0;
		video++;
	}
	/* *(video + 1) = 'H'; */
	/* *(video + 2) = 0xf0; */
	/* *(video + 3) = 'i'; */
	/* *(video + 4) = 0xf0; */
	/* video++; */
	while(1);
}

