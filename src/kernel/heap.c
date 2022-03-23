#include "heap.h"

void* heap_start   = (void*)HEAP_START;
void* heap_end     = (void*)HEAP_END;
void* heap_current = (void*)HEAP_START;

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
