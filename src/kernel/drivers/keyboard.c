enum KEYCODE {
	NULL_KEY = 0,

	Q = 0x10,
	W = 0x11,
	E = 0x12,
	R = 0x13,
	T = 0x14,
	Y = 0x15,
	U = 0x16,
	I = 0x17,
	O = 0x18,
	P = 0x19,
	A = 0x1E,
	S = 0x1F,
	D = 0x20,
	F = 0x21,
	G = 0x22,
	H = 0x23,
	J = 0x24,
	K = 0x25,
	L = 0x26,
	Z = 0x2C,
	X = 0x2D,
	C = 0x2E,
	V = 0x2F,
	B = 0x30,
	N = 0x31,
	M = 0x32,

	ONE   = 0x2,
	TWO   = 0x3,
	THREE = 0x4,
	FOUR  = 0x5,
	FIVE  = 0x6,
	SIX   = 0x7,
	SEVEN = 0x8,
	EIGHT = 0x9,
	NINE  = 0xA,
	ZERO  = 0xb,

	BACKTICK      = 0x29,
	HYPHEN        = 0x0c,
	EQUAL         = 0x0d,
	LEFT_BRACKET  = 0x1a,
	RIGHT_BRACKET = 0x1b,
	SEMICOLON     = 0x27,
	SINGLE_QUOTE  = 0x28,
	BACKSLASH     = 0x2b,
	COMMA         = 0x33,
	PERIOD        = 0x34,
	FORWARD_SLASH = 0x35,
	LESS_THAN     = 0x56,

	SPACE     = 0x39,
	ENTER     = 0x1C,
	ESCAPE    = 0x01,
	BACKSPACE = 0x0e,
};

static char* _qwertyuiop = "qwertyuiop"; // 0x10-0x1c
static char* _asdfghjkl  = "asdfghjkl";   // 0x1e-0x2c
static char* _zxcvbnm    = "zxcvbnm";
static char* _num        = "0123456789";

uint8_t keyboard_to_ascii(uint8_t key) {
	// Transform released to pressed.
	if (key >= 0x80) {
		key -= 0x80;
	}

	switch (key) {
		case Q:
			return _qwertyuiop[0];
		case W:
			return _qwertyuiop[1];
		case E:
			return _qwertyuiop[2];
		case R:
			return _qwertyuiop[3];
		case T:
			return _qwertyuiop[4];
		case Y:
			return _qwertyuiop[5];
		case U:
			return _qwertyuiop[6];
		case I:
			return _qwertyuiop[7];
		case O:
			return _qwertyuiop[8];
		case P:
			return _qwertyuiop[9];

		case A:
			return _asdfghjkl[0];
		case S:
			return _asdfghjkl[1];
		case D:
			return _asdfghjkl[2];
		case F:
			return _asdfghjkl[3];
		case G:
			return _asdfghjkl[4];
		case H:
			return _asdfghjkl[5];
		case J:
			return _asdfghjkl[6];
		case K:
			return _asdfghjkl[7];
		case L:
			return _asdfghjkl[8];

		case Z:
			return _zxcvbnm[0];
		case X:
			return _zxcvbnm[1];
		case C:
			return _zxcvbnm[2];
		case V:
			return _zxcvbnm[3];
		case B:
			return _zxcvbnm[4];
		case N:
			return _zxcvbnm[5];
		case M:
			return _zxcvbnm[6];

		case ZERO:
			return _num[0];
		case ONE:
			return _num[1];
		case TWO:
			return _num[2];
		case THREE:
			return _num[3];
		case FOUR:
			return _num[4];
		case FIVE:
			return _num[5];
		case SIX:
			return _num[6];
		case SEVEN:
			return _num[7];
		case EIGHT:
			return _num[8];
		case NINE:
			return _num[9];

		case BACKTICK:
			return '`';
		case HYPHEN:
			return '-';
		case EQUAL:
			return '=';
		case LEFT_BRACKET:
			return '[';
		case RIGHT_BRACKET:
			return ']';
		case SEMICOLON:
			return ';';
		case SINGLE_QUOTE:
			return '\'';
		case BACKSLASH:
			return '\\';
		case COMMA:
			return ',';
		case PERIOD:
			return '.';
		case FORWARD_SLASH:
			return '/';
		case LESS_THAN:
			return '<';

		case SPACE:
			return ' ';
		case ENTER:
			return '\n';
		case ESCAPE:
			return '\x1b';
		case BACKSPACE:
			return '\b';

		default:
			return 0;
	}
}

enum KEY_STATE {
	KEY_STATE_RELEASED = 0,
	KEY_STATE_PRESSED = 1,
};

/* struct Key { */
/* 	KEY key; */
/* 	KEY_STATE pressed; */
/* }; */

int caret_x = 0;
int caret_y = 3*LARGE_FONT_CELL_HEIGHT;
extern void keyboard_handler() {
	PIC_sendEOI(0x22);

	uint8_t rawkey = inb(0x60);

	if (rawkey > 0x80) {
		PIC_sendEOI(0x22);
		return;
	}

	uint8_t c = keyboard_to_ascii(rawkey);
	if (!c) {
		printf("Unk key: %d  ", 200, 200, NULL, rawkey);
		PIC_sendEOI(0x22);
		return;
	}

	if (is_print(c)) {
		printf("%c", caret_x, caret_y, NULL, c);
		caret_x += LARGE_FONT_CELL_WIDTH;
	} else if (c == '\b') {
		if (caret_x > 0) {
			caret_x -= LARGE_FONT_CELL_WIDTH;
			printf("%c", caret_x, caret_y, NULL, ' ');
		}
	} else if (c == '\n') {
		caret_x  = 0;
		caret_y += LARGE_FONT_CELL_HEIGHT;
	}
}
