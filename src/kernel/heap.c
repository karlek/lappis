#include "heap.h"

void* heap_start   = NULL;
void* heap_end     = NULL;
void* heap_current = NULL;

uint8_t * KERNEL_DATA() {
	return (uint8_t *)KERNEL_DATA_ADDR;
}

void * HEAP_START() {
	// TODO: ensure that kernel memory and heap does not overlap. include guard
	// page.
	return KERNEL_DATA() + 0x100000;
}

void * HEAP_END() {
	return (void *)KERNEL_DATA_END_ADDR;
}


void init_heap() {
	heap_start   = HEAP_START();
	heap_end     = HEAP_END();
	heap_current = HEAP_START();
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
