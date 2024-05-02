#include "userland.h"

void sys_print(uint8_t *s, uint64_t len) {
	// $0 is immediate value 0 in AT-T syntax.
	asm volatile("mov $0, %%rax\n"
				 "mov %0, %%rdi\n"
				 "mov %1, %%rsi\n"
				 "syscall\n"
				 :: "r"(s), "r"(len) : "rax", "rdi", "rsi");
}

uint64_t strlen(uint8_t* s) {
	uint64_t len = 0;
	while (*s++) {
		len++;
	}
	return len;
}

#define EVER ;;

void elf_userland() {
	char buf[128];

	sprintf(&buf[0], "Hello, %s!", "from userland");
	uint64_t len = strlen((uint8_t *)&buf[0]);

	sys_print((uint8_t *)&buf[0], len);

	for (EVER) {}
}
