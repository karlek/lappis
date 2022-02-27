#include "ps2.c"
#include "drivers/keyboard.c"
#include "drivers/mouse.c"
#include "drivers/ata.c"

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
	// Remap PIC interrupt numbers.
	PIC_remap(0x20, 0x28);

	debug("idt_init: initating IDT");
	idtr.base  = (uint64_t)&idt[0];
	idtr.limit = (uint16_t)sizeof(idt_entry_t) * IDT_MAX_DESCRIPTORS - 1;

	// Highest number should correspond to the length of isr_stub_table in
	// `idt.asm`.
	for (uint8_t vector = 0; vector <= 47; vector++) {
		idt_set_descriptor(vector, isr_stub_table[vector], 0x8E);
	}

	enable_mouse();
	enable_ata();

	// Load the new IDT.
	__asm__ volatile ("lidt %0" : : "m"(idtr));
	// Set the interrupt flag.
	__asm__ volatile ("sti");

	debug("idt_init: IDT initialized");
}
