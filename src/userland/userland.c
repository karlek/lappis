#include "userland.h"

void sys_print(uint8_t *s, uint64_t len) {
	asm volatile("mov $0, %%rax\n"
				 "syscall\n"
				 :: "r"(s), "r"(len) : "rax", "r11", "rcx");
}

uint64_t strlen(uint8_t* s) {
	uint64_t len = 0;
	while (*s++) {
		len++;
	}
	return len;
}

void yay_userland() {
	char buf[128];

	sprintf(buf, "Hello, %s!", "world");
	uint64_t len = strlen(buf);

	sys_print(buf, len);
}
