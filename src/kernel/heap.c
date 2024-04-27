#include "heap.h"

#define PAGE_SIZE 0x200000

void* heap_start   = NULL;
void* heap_end     = NULL;
void* heap_current = NULL;

void* userland_heap_start   = NULL;
void* userland_heap_end     = NULL;
void* userland_heap_current = NULL;

uint8_t * KERNEL_DATA() {
	return (uint8_t *)((uint64_t)KERNEL_DATA_ADDR);
}

void * HEAP_START() {
	// TODO: ensure that kernel memory and heap does not overlap. include guard
	// page.
	return KERNEL_DATA() + 0x100000;
}

void * HEAP_END() {
	return (void *)((uint64_t)KERNEL_DATA_END_ADDR);
}

uint8_t * USERLAND() {
	return (uint8_t *)((uint64_t)USERLAND_ADDR);
}

void * USERLAND_HEAP_START() {
	// TODO: ensure that userland memory and heap does not overlap. include guard
	// page.
	return USERLAND() + PAGE_SIZE + 0x100000; // ignore guard page and give room for userland stack.
}

void * USERLAND_HEAP_END() {
	return (void *)((uint64_t)USERLAND_END_ADDR);
}

void init_heap() {
	heap_start   = HEAP_START();
	heap_end     = HEAP_END();
	heap_current = HEAP_START();
}

void init_userland_heap() {
	userland_heap_start   = USERLAND_HEAP_START();
	userland_heap_end     = USERLAND_HEAP_END();
	userland_heap_current = USERLAND_HEAP_START();
}

void* malloc(uint64_t size) {
	if (heap_current + size >= heap_end) {
		error("Out of heap memory");
		return NULL;
	}

	void* ptr = heap_current;
	// Zero out the memory.
	for (uint64_t i = 0; i < size; i++) {
		((uint8_t*)ptr)[i] = 0;
	}

	heap_current += size;

	return ptr;
}

void* userland_malloc(uint64_t size) {
	if (userland_heap_current + size >= userland_heap_end) {
		error("Out of userland heap memory");
		return NULL;
	}

	void* ptr = userland_heap_current;
	// Zero out the memory.
	for (uint64_t i = 0; i < size; i++) {
		((uint8_t*)ptr)[i] = 0;
	}

	userland_heap_current += size;

	return ptr;
}
