#include "pic.h"

void PIC_sendEOI(uint8_t irq) {
	if (irq >= 8) {
		outb(PIC2_COMMAND, PIC_EOI);
	}

	outb(PIC1_COMMAND, PIC_EOI);
}

/*
arguments:
    offset1 - vector offset for primary PIC
        vectors on the primary become offset1..offset1+7
    offset2 - same for secondary PIC: offset2..offset2+7
*/
void PIC_remap(uint16_t offset1, uint16_t offset2) {
	debug("PIC_remap: start.");
	uint8_t a1, a2;

	// Save masks.
	a1 = inb(PIC1_DATA);
	a2 = inb(PIC2_DATA);

	// Starts the initialization sequence (in cascade mode).
	outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);
	outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
	// ICW2: primary PIC vector offset
	outb(PIC1_DATA, offset1);
	// ICW2: secondary PIC vector offset
	outb(PIC2_DATA, offset2);
	// ICW3: tell primary PIC that there is a secondary PIC
	outb(PIC1_DATA, 4);

	// At IRQ2 (0000 0100)
	// ICW3: tell secondary PIC its cascade identity (0000 0010)
	outb(PIC2_DATA, 2);

	outb(PIC1_DATA, ICW4_8086);
	outb(PIC2_DATA, ICW4_8086);

	// Restore saved masks.
	outb(PIC1_DATA, a1);
	outb(PIC2_DATA, a2);
	debug("PIC_remap: done.");
}
