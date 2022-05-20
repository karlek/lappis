#include "userland.h"

void sys_print(const char *m) {
	asm volatile("mov $0, %%rax\n"
				 "mov %0, %%rbx\n"
				 "syscall\n"
				 :: "r"(m) : "rax", "rbx");
}

void yay_userland() {
	char buf[128];

	sprintf(buf, "Hello, %s!", "world");

	sys_print(buf);
}
