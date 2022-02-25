int is_print(uint8_t c) {
	return (c >= ' ' && c <= '~');
}

int strlen(unsigned char * s) {
	int len = 0;
	while (*s++) {
		len++;
	}
	return len;
}

// inb4 vulns
void strcat(unsigned char *dest, const unsigned char *src) {
	while (*dest) {
		dest++;
	}
	while (*src) {
		*dest++ = *src++;
	}
	*dest = '\0';
}

void itoa(int num, unsigned char *str) {
	bool is_negative = false;
	if (num < 0) {
		is_negative = true;
		num = -num;
	}

	// Handle MinInt case.
	if (num == (-1 << 31)) {
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

	int offset = 0;
	unsigned char tmp[10] = {0};
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
void htox(unsigned int num, unsigned char *str) {
	int offset = 0;
	unsigned char tmp[8] = {0};
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

	*(str++) = '0';
	*(str++) = 'x';
	while (offset > 0) {
		*(str++) = tmp[--offset];
	}
	str[offset] = '\0';
}

