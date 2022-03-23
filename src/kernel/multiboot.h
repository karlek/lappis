#include <stdint.h>

#include "multiboot2.h"
#include "serial.h"

typedef struct multiboot_info multiboot_info_t;

void parse_multiboot_header(multiboot_info_t* boot_info);
