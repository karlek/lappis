#include <stdint.h>
#include "drivers/keyboard.h"

void disable_interrupt() {
	asm volatile("cli");
}

void enable_interrupt() {
	asm volatile("sti");
}

void sys_print_new(void *u_str, uint64_t size) {
	void* k_p = malloc(size);
	userland_memcpy(k_p, u_str, size);
	debug_buffer(k_p, size);
}

void sys_getch_new(uint8_t* u_c) {
	// Otherwise we will hang for ever.
	enable_interrupt();

	uint8_t c = 0;
	while(c == 0) {
		circ_buf_pop(&c);
	}
	userland_memcpy(u_c, &c, 1);

	disable_interrupt();
}

// The way linux does it is to use `struct pt_regs`.
// https://lwn.net/Articles/750536/
// 
// NOTE: arbitrary func ptr for minimum type safety.
typedef void (*syscall_ptr_t)();
const syscall_ptr_t syscall_table[2] = {
	&sys_print_new,
	&sys_getch_new,
};
