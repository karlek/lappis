#include "userland.h"
#include <stdbool.h>

uint64_t strlen(uint8_t* s) {
	uint64_t len = 0;
	while (*s++) {
		len++;
	}
	return len;
}

void sys_print(uint8_t* s, uint64_t len) {
	// $0 is immediate value 0 in AT-T syntax.
	asm volatile("mov $0, %%rax\n"
	             "mov %0, %%rdi\n"
	             "mov %1, %%rsi\n"
	             "syscall\n" ::"r"(s),
	             "r"(len)
	             : "rax", "rdi", "rsi");
}

uint8_t sys_getch() {
	uint64_t c;
	asm volatile("mov $1, %%rax\n"
	             "mov %0, %%rdi\n"
	             "syscall\n" ::"r"(&c)
	             : "rax", "rdi");
	return c & 0xff;
}

void get_line(uint8_t line[128]) {
	uint8_t  c;
	uint64_t i = 0;
	while ((c = sys_getch())) {
		if ('\n' == c) {
			break;
		}
		line[i] = c;
		i++;
	}
}

void __attribute__((noinline)) debug_interrupt() {
	// NOTE: This will actually throw a general protection fault, since it's a
	// privileged instruction. So we just hook this empty void stub instead and
	// pretend that it works!

	/* asm volatile("int3"); */
}

#define EVER                                                                   \
	;                                                                          \
	;

void strip(uint8_t* s) {
	bool     stop = true;
	uint32_t i    = strlen(s) - 1;
	for (; i > 0; i--) {
		if (i == ' ') {
			stop = false;
		}
		if (i == '\n') {
			stop = false;
		}
		if (i == '\t') {
			stop = false;
		}
		if (stop) {
			break;
		}
	}

	if (strlen(s) - 1 == i) {
		return;
	}
	s[i] = '\0';
}

bool strcmp(uint8_t* a, uint8_t* b) {
	if (strlen(a) != strlen(b)) {
		return false;
	}
	for (uint32_t i = 0; i < strlen(a); i++) {
		if (a[i] != b[i]) {
			return false;
		}
	}
	return true;
}

void memset(uint8_t* p, uint8_t c, uint32_t len) {
	for (uint32_t i = 0; i < len; i++) {
		p[i] = c;
	}
}

void elf_userland() {
	uint8_t buf[128];

	sprintf(&buf[0], "Hello, %s!", "from userland");
	uint64_t len = strlen(buf);

	sys_print(buf, len);

	for (EVER) {
		uint8_t printl[128];
		uint8_t readl[128];
		memset(printl, 0, sizeof printl);
		memset(readl, 0, sizeof readl);
		get_line(readl);

		// Remove trailing whitespace.
		strip(readl);

		if (strcmp(readl, "pwd")) {
			sprintf(&printl[0], "> %s\n", "/");
			sys_print(printl, strlen(printl));
		}
	}
}
