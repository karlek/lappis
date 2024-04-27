#include "userland.h"

void sys_print(uint8_t *s, uint64_t len) {
	asm volatile("mov $0, %%rax\n"
				 "mov %0, %%rbx\n"
				 "syscall\n"
				 :: "r"(s), "r"(len) : "rax", "rbx");
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
