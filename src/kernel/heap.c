// 96MiB heap
#define HEAP_START 0x200000
#define HEAP_END   0x3e00000

// Kernel stack:       0x4000000 - 0x4800000
// Frame buffer:       0x4800000 - 0x4e00000

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
