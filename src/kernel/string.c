bool is_print(uint8_t c) {
	return (c >= ' ' && c <= '~');
}

uint32_t strlen(uint8_t* s) {
	uint32_t len = 0;
	while (*s++) {
		len++;
	}
	return len;
}

// inb4 vulns
void strcat(uint8_t* dest, const uint8_t* src) {
	while (*dest) {
		dest++;
	}
	while (*src) {
		*dest++ = *src++;
	}
	*dest = '\0';
}

void memset(uint8_t* dest, uint8_t val, uint32_t len) {
	for (uint32_t i = 0; i < len; i++) {
		dest[i] = val;
	}
}

uint64_t strrchr(uint8_t* str, uint8_t c) {
	uint64_t i = strlen(str);
	while (i >= 0) {
		if (str[i] == c) {
			return i;
		}
		i--;
	}
	return 0;
}

void itoa(int64_t num, uint8_t* str) {
	bool is_negative = false;
	if (num < 0) {
		is_negative = true;
		num         = -num;
	}

	// Handle MinInt case.
	if (num == -2147483648) {
		strcat(str, "-2147483648");
		return;
	}
	if (num == 0) {
		strcat(str, "0");
		return;
	}

	if (is_negative) {
		str[0] = '-';
		str++;
	}

	uint8_t offset  = 0;
	uint8_t tmp[10] = {0};
	while (num > 0) {
		tmp[offset++] = (num % 10) + '0';
		num /= 10;
	}
	while (offset > 0) {
		*(str++) = tmp[--offset];
	}
	str[offset] = '\0';
}

// TODO: This is pretty wonky.
void htox(int64_t num, uint8_t* str, bool prefix) {
	uint8_t offset = 0;
	uint8_t tmp[8] = {0};
	if (num > 0) {
		while (num > 0) {
			uint8_t hdigit = (num % 16);
			if (hdigit < 10) {
				tmp[offset++] = hdigit + '0';
			} else {
				tmp[offset++] = hdigit - 10 + 'a';
			}
			num /= 16;
		}
	} else {
		tmp[offset++] = '0';
	}

	if (prefix) {
		*(str++) = '0';
		*(str++) = 'x';
	}
	if (strlen(tmp) % 2 != 0) {
		*(str++) = '0';
	}
	while (offset > 0) {
		*(str++) = tmp[--offset];
	}
	str[offset] = '\0';
}

// Does not handle null pointers.
bool streq(uint8_t* s1, uint8_t* s2) {
	if (s1 == NULL || s2 == NULL) {
		return false;
	}
	if (s1 == s2) {
		return true;
	}
	if (strlen(s1) != strlen(s2)) {
		return false;
	}
	for (int i = 0; i < strlen(s1); i++) {
		if (s1[i] != s2[i]) {
			return false;
		}
	}
	return true;
}
