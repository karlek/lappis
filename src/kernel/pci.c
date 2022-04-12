#include "pci.h"

uint32_t pci_read_reg(uint8_t bus, uint8_t slot, uint8_t func, uint8_t reg) {
	uint32_t address;
	uint32_t lbus  = (uint32_t)bus;
	uint32_t lslot = (uint32_t)slot;
	uint32_t lfunc = (uint32_t)func;
	uint32_t lreg  = (uint32_t)reg * 4;
	uint16_t tmp   = 0;

	// Create configuration address as per Figure 1
	address = 0x80000000 | (lbus << 16) | (lslot << 11) | (lfunc << 8) | lreg;

	// Write out the address
	outl(PCI_CONFIG_ADDRESS, address);

	uint32_t data = inl(PCI_CONFIG_DATA);
	if (data == 0xFFFFFFFF) {
		return 0;
	}
	return data;
}

void enumerate_pci_devices() {
	debug("Enumerating PCI devices...");
	for (uint16_t bus = 0; bus < 256; bus++) {
		for (uint8_t slot = 0; slot < 32; slot++) {
			for (uint8_t func = 0; func < 8; func++) {
				if (pci_read_reg((uint8_t)bus, slot, func, 0) == 0) {
					continue;
				}
				for (uint8_t reg = 0; reg < 0xF; reg++) {
					uint32_t data = pci_read_reg((uint8_t)bus, slot, func, reg);
					if (data == 0) {
						continue;
					}
					debug("%x:%x.%d %x:%x", bus, slot, func, data & 0xFFFF,
					      data >> 16);
				}
			}
		}
	}
}
