#ifndef ZIP_H
#define ZIP_H

#include <stdbool.h>
#include <stdint.h>

#include "heap.h"
#include "memcpy.h"

typedef struct {
	uint8_t* name;
	uint8_t* data;
	uint32_t size;
} file_t;

typedef struct {
	file_t** files;
	uint32_t num_files;
} zip_fs_t;


uint64_t peek_zip(uint8_t* buf);
void read_zip(uint8_t* buf, uint64_t len, zip_fs_t* zipfs);

#endif
