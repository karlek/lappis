#include "heap.h"

void* heap_start = NULL;
void* heap_end = NULL;
void* heap_current = NULL;

void* HEAP_START() {
	return P2_KERNEL_DATA_ADDR_EXPORT+0x1000;
}
void* HEAP_END() {
	return P2_KERNEL_DATA_ADDR_EXPORT+0x8000000;
}
uint64_t USERLAND() {
	return P2_USERLAND_ADDR_EXPORT;
}

void init_heap() {
	heap_start   = (void*)HEAP_START();
	heap_end     = (void*)HEAP_END();
	heap_current = (void*)HEAP_START();
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

void* userland_alloc(uint64_t addr, uint64_t size) {
	void* ptr = (void *) addr;
	// Zero out the memory.
	for (uint64_t i = 0; i < size; i++) {
		((uint8_t*)ptr)[i] = 0;
	}

	return ptr;
}
