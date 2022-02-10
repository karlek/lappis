#define IDT_MAX_DESCRIPTORS 256

void num_to_error_name(int interrupt_number, unsigned char *error_name) {
	switch (interrupt_number) {
		case 0:
			strcat(error_name, "Divide Error");
			break;
		case 1:
			strcat(error_name, "Debug");
			break;
		case 2:
			strcat(error_name, "NMI Interrupt");
			break;
		case 3:
			strcat(error_name, "Breakpoint");
			break;
		case 4:
			strcat(error_name, "Overflow");
			break;
		case 5:
			strcat(error_name, "Bound Range Exceeded");
			break;
		case 6:
			strcat(error_name, "Invalid Opcode");
			break;
		case 7:
			strcat(error_name, "Device Not Available");
			break;
		case 8:
			strcat(error_name, "Double Fault");
			break;
		case 9:
			strcat(error_name, "Coprocessor Segment Overrun");
			break;
		case 10:
			strcat(error_name, "Invalid TSS");
			break;
		case 11:
			strcat(error_name, "Segment Not Present");
			break;
		case 12:
			strcat(error_name, "Stack-Segment Fault");
			break;
		case 13:
			strcat(error_name, "General Protection Fault");
			break;
		case 14:
			strcat(error_name, "Page Fault");
			break;
		case 15:
			strcat(error_name, "Reserved");
			break;
		case 16:
			strcat(error_name, "x87 FPU Floating-Point Error");
			break;
		case 17:
			strcat(error_name, "Alignment Check");
			break;
		case 18:
			strcat(error_name, "Machine-Check");
			break;
		case 19:
			strcat(error_name, "SIMD Floating-Point Exception");
			break;
		case 20:
			strcat(error_name, "Virtualization Exception");
			break;
		case 21:
			strcat(error_name, "Reserved");
			break;
		case 22:
			strcat(error_name, "Reserved");
			break;
		case 23:
			strcat(error_name, "Reserved");
			break;
		case 24:
			strcat(error_name, "Reserved");
			break;
		case 25:
			strcat(error_name, "Reserved");
			break;
		case 26:
			strcat(error_name, "Reserved");
			break;
		case 27:
			strcat(error_name, "Reserved");
			break;
		case 28:
			strcat(error_name, "Hypervisor Injection Exception");
			break;
		case 29:
			strcat(error_name, "VMM Communication Exception");
			break;
		case 30:
			strcat(error_name, "Security Exception");
			break;
		case 31:
			strcat(error_name, "Reserved");
			break;
		default:
			strcat(error_name, "Unknown interrupt");
			break;
	}
}

typedef struct {
	uint16_t    isr_low;      // The lower 16 bits of the ISR's address
	uint16_t    kernel_cs;    // The GDT segment selector that the CPU will load into CS before calling the ISR
	uint8_t     ist;          // The IST in the TSS that the CPU will load into RSP; set to zero for now
	uint8_t     attributes;   // Type and attributes; see the IDT page
	uint16_t    isr_mid;      // The higher 16 bits of the lower 32 bits of the ISR's address
	uint32_t    isr_high;     // The higher 32 bits of the ISR's address
	uint32_t    reserved;     // Set to zero
} __attribute__((packed)) idt_entry_t;

typedef struct {
	uint16_t    limit;
	uint64_t    base;
} __attribute__((packed)) idtr_t;

// Create an array of IDT entries; aligned for performance
__attribute__((aligned(0x10))) static idt_entry_t idt[IDT_MAX_DESCRIPTORS];

static idtr_t idtr;

// Defined in idt.asm
extern void* isr_stub_table[];

__attribute__((noreturn)) void exception_handler() {
    __asm__ volatile ("cli; hlt"); // Completely hangs the computer
}

void idt_set_descriptor(uint8_t vector, void* isr, uint8_t flags) {
    idt_entry_t* descriptor = &idt[vector];

    descriptor->isr_low    =  (uint64_t)isr & 0xFFFF;
    descriptor->isr_mid    = ((uint64_t)isr >> 16) & 0xFFFF;
    descriptor->isr_high   = ((uint64_t)isr >> 32) & 0xFFFFFFFF;
    descriptor->kernel_cs  = 0x08;
    descriptor->ist        = 0;
    descriptor->attributes = flags;
    descriptor->reserved   = 0;
}

void idt_init() {
    idtr.base  = (uint64_t)&idt[0];
    idtr.limit = (uint16_t)sizeof(idt_entry_t) * IDT_MAX_DESCRIPTORS - 1;

    for (uint8_t vector = 0; vector <= 33; vector++) {
        idt_set_descriptor(vector, isr_stub_table[vector], 0x8E);
    }
 
    __asm__ volatile ("lidt %0" : : "m"(idtr));  // load the new IDT
    __asm__ volatile ("sti");                    // set the interrupt flag
}

enum KEYCODE {
	NULL_KEY  = 0,

	Q_PRESSED = 0x10,
	W_PRESSED = 0x11,
	E_PRESSED = 0x12,
	R_PRESSED = 0x13,
	T_PRESSED = 0x14,
	Y_PRESSED = 0x15,
	U_PRESSED = 0x16,
	I_PRESSED = 0x17,
	O_PRESSED = 0x18,
	P_PRESSED = 0x19,
	A_PRESSED = 0x1E,
	S_PRESSED = 0x1F,
	D_PRESSED = 0x20,
	F_PRESSED = 0x21,
	G_PRESSED = 0x22,
	H_PRESSED = 0x23,
	J_PRESSED = 0x24,
	K_PRESSED = 0x25,
	L_PRESSED = 0x26,
	Z_PRESSED = 0x2C,
	X_PRESSED = 0x2D,
	C_PRESSED = 0x2E,
	V_PRESSED = 0x2F,
	B_PRESSED = 0x30,
	N_PRESSED = 0x31,
	M_PRESSED = 0x32,

	ZERO_PRESSED  = 0x29,
	ONE_PRESSED   = 0x2,
	TWO_PRESSED   = 0x3,
	THREE_PRESSED = 0x4,
	FOUR_PRESSED  = 0x5,
	FIVE_PRESSED  = 0x6,
	SIX_PRESSED   = 0x7,
	SEVEN_PRESSED = 0x8,
	EIGHT_PRESSED = 0x9,
	NINE_PRESSED  = 0xA,

	POINT_PRESSED      = 0x34,
	SPACE_PRESSED      = 0x39,
	ENTER_PRESSED      = 0x1C,
	BACKSPACE_PRESSED  = 0x0e,
	BACKSPACE_RELEASED = 0x8e,
};

static char* _qwertyuiop = "qwertyuiop"; // 0x10-0x1c
static char* _asdfghjkl = "asdfghjkl";   // 0x1e-0x2c
static char* _zxcvbnm = "zxcvbnm";
static char* _num = "123456789";

uint8_t keyboard_to_ascii(uint8_t key) {
	switch (key) {
		case Q_PRESSED:
			return _qwertyuiop[0];
		case W_PRESSED:
			return _qwertyuiop[1];
		case E_PRESSED:
			return _qwertyuiop[2];
		case R_PRESSED:
			return _qwertyuiop[3];
		case T_PRESSED:
			return _qwertyuiop[4];
		case Y_PRESSED:
			return _qwertyuiop[5];
		case U_PRESSED:
			return _qwertyuiop[6];
		case I_PRESSED:
			return _qwertyuiop[7];
		case O_PRESSED:
			return _qwertyuiop[8];
		case P_PRESSED:
			return _qwertyuiop[9];

		case A_PRESSED:
			return _asdfghjkl[0];
		case S_PRESSED:
			return _asdfghjkl[1];
		case D_PRESSED:
			return _asdfghjkl[2];
		case F_PRESSED:
			return _asdfghjkl[3];
		case G_PRESSED:
			return _asdfghjkl[4];
		case H_PRESSED:
			return _asdfghjkl[5];
		case J_PRESSED:
			return _asdfghjkl[6];
		case K_PRESSED:
			return _asdfghjkl[7];
		case L_PRESSED:
			return _asdfghjkl[8];

		case Z_PRESSED:
			return _zxcvbnm[0];
		case X_PRESSED:
			return _zxcvbnm[1];
		case C_PRESSED:
			return _zxcvbnm[2];
		case V_PRESSED:
			return _zxcvbnm[3];
		case B_PRESSED:
			return _zxcvbnm[4];
		case N_PRESSED:
			return _zxcvbnm[5];
		case M_PRESSED:
			return _zxcvbnm[6];

		case ZERO_PRESSED:
			return _num[0];
		case ONE_PRESSED:
			return _num[1];
		case TWO_PRESSED:
			return _num[2];
		case THREE_PRESSED:
			return _num[3];
		case FOUR_PRESSED:
			return _num[4];
		case FIVE_PRESSED:
			return _num[5];
		case SIX_PRESSED:
			return _num[6];
		case SEVEN_PRESSED:
			return _num[7];
		case EIGHT_PRESSED:
			return _num[8];
		case NINE_PRESSED:
			return _num[9];

		case POINT_PRESSED:
			return '.';
		case SPACE_PRESSED:
			return ' ';
		case ENTER_PRESSED:
			return '\n';

		case BACKSPACE_PRESSED:
		case BACKSPACE_RELEASED:
			return '\b';
		default:
			return 0;
	}
}

int is_print(uint8_t c) {
	return (c >= ' ' && c <= '~');
}

int caret_x = 0;
int caret_y = 3*LARGE_FONT_CELL_HEIGHT;
extern void keyboard_handler() {
	uint8_t key = inb(0x60);
	clear_screen_vbe();
	if (key > 0x90) {
		PIC_sendEOI(0x22);
		return;
	}
	if (!keyboard_to_ascii(key)) {
		PIC_sendEOI(0x22);
		return;
	}

	uint8_t c = keyboard_to_ascii(key);
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
	PIC_sendEOI(0x22);
}
