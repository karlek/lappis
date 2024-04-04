#ifndef STRING_H
#define STRING_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void itoa(int64_t num, uint8_t* str);
uint64_t strrchr(uint8_t* str, uint8_t c);
bool streq(uint8_t* s1, uint8_t* s2);
bool streqn(uint8_t* s1, uint8_t* s2, uint64_t n);
uint32_t strlen(uint8_t* s);
void strcat(uint8_t* dest, const uint8_t* src);
bool is_print(uint8_t c);

#endif
