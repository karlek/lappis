#include "ata.h"

extern void ata_primary_handler() {
	/* debug("Primary handler"); */
	PIC_sendEOI(0x20 + ATA_PRIMARY_IRQ);
}

extern void ata_secondary_handler() {
	/* debug("Secondary handler"); */
	PIC_sendEOI(0x20 + ATA_SECONDARY_IRQ);
}

void ide_select_drive(uint8_t bus, uint8_t drive) {
	uint16_t io = 0;
	if (bus == ATA_PRIMARY_BUS) {
		io = ATA_PRIMARY_IO;
	} else if (bus == ATA_SECONDARY_BUS) {
		io = ATA_SECONDARY_IO;
	} else {
		error("Invalid bus!");
		return;
	}

	uint8_t command = 0;
	if (drive == ATA_PRIMARY_DRIVE) {
		command = 0xA0;
	} else if (drive == ATA_SECONDARY_DRIVE) {
		command = 0xB0;
	} else {
		error("Invalid drive!");
		return;
	}
	outb(io + ATA_REG_HDDEVSEL, command);
}

bool ide_identify(uint8_t bus, uint8_t drive, uint8_t* ide_buf) {
	ide_select_drive(bus, drive);

	uint16_t io = bus == ATA_PRIMARY_BUS ? ATA_PRIMARY_IO : ATA_SECONDARY_IO;

	// ATA specs say these values must be zero before sending IDENTIFY.
	outb(io + ATA_REG_SECCOUNT0, 0);
	outb(io + ATA_REG_LBA0, 0);
	outb(io + ATA_REG_LBA1, 0);
	outb(io + ATA_REG_LBA2, 0);

	// Now we can send IDENTIFY command.
	outb(io + ATA_REG_COMMAND, ATA_CMD_IDENTIFY);

	uint8_t status = inb(io + ATA_REG_STATUS);
	if (!status) {
		error("Status was empty!");
		return false;
	}

	// TODO: This hangs when precedence is correct! Right now it's bugged and
	// working.. Maybe we should invert the equality?
	while ((inb(io + ATA_REG_STATUS) & ATA_SR_BSY) != 0) {}
	status = inb(io + ATA_REG_STATUS);
	if (status & ATA_SR_ERR) {
		error("unknown error: TODO: implement IDE error handling");
		return false;
	}

	while (!(status & ATA_SR_DRQ)) {
		status = inb(io + ATA_REG_STATUS);
		if (status & ATA_SR_ERR) {
			error("unknown error: TODO: implement IDE error handling");
			return false;
		}
	}

	// Now we can read the name of the drive.
	for (uint32_t i = 0; i < 256; i++) {
		uint16_t tmp       = inw(io + ATA_REG_DATA);
		ide_buf[i * 2]     = tmp >> 8;
		ide_buf[i * 2 + 1] = tmp & 0xFF;
	}
	ide_buf[ATA_IDENT_MODEL + 40] = '\x00';

	return true;
}

void ide_400ns_delay(uint16_t io) {
	for (uint32_t i = 0; i < 4; i++) {
		inb(io + ATA_REG_ALTSTATUS);
	}
}

void ide_print_error(uint16_t io) {
	//error("IDE:");

	uint8_t status = inb(io + ATA_REG_ERROR);
	if (status & ATA_ER_AMNF) {
		error("- No Address Mark Found");
	}
	if (status & ATA_ER_TK0NF) {
		error("- No Media or Media Error");
	}
	if (status & ATA_ER_ABRT) {
		//error("- Command Aborted");
	}
	if (status & ATA_ER_MCR) {
		error("- No Media or Media Error");
	}
	if (status & ATA_ER_IDNF) {
		error("- ID mark not Found");
	}
	if (status & ATA_ER_MC) {
		error("- No Media or Media Error");
	}
	if (status & ATA_ER_UNC) {
		error("- Uncorrectable Data Error");
	}
	if (status & ATA_ER_BBK) {
		error("- Bad Sectors");
	}
}

void ide_poll(uint16_t io, bool advanced_check) {
	ide_400ns_delay(io);

	for (;;) {
		uint8_t status  = inb(io + ATA_REG_STATUS);
		bool    is_busy = (status & ATA_SR_BSY) != 0;
		if (!is_busy) {
			break;
		}
	}

	if (!advanced_check) {
		return;
	}

	uint8_t status = inb(io + ATA_REG_STATUS);
	bool    is_err = (status & ATA_SR_ERR) != 0;
	if (is_err) {
		//error("Unknown IDE error. TODO: implement IDE error handling");
		ide_print_error(io);
		return;
	}
	bool is_device_fault = (status & ATA_SR_DF) != 0;
	if (is_device_fault) {
		error("Device fault. TODO: implement IDE error handling");
		return;
	}
	bool is_not_drq = (status & ATA_SR_DRQ) == 0;
	if (is_not_drq) {
		error("DRQ not set. TODO: implement IDE error handling");
		return;
	}

	// We are done!
}

void ide_read_sector(uint8_t* buf, uint32_t lba, ide_dev_t* dev) {
	uint8_t  drive = dev->drive;
	uint16_t io    = dev->io;

	bool    is_primary    = drive == ATA_PRIMARY_DRIVE;
	uint8_t command       = is_primary ? 0xE0 : 0xF0;

	outb(io + ATA_REG_HDDEVSEL, command | (uint8_t)((lba >> 24) & 0x0F));
	outb(io + 1, 0x00);
	outb(io + ATA_REG_SECCOUNT0, 1);
	outb(io + ATA_REG_LBA0, (uint8_t)(lba));
	outb(io + ATA_REG_LBA1, (uint8_t)(lba >> 8));
	outb(io + ATA_REG_LBA2, (uint8_t)(lba >> 16));
	outb(io + ATA_REG_COMMAND, ATA_CMD_READ_PIO);

	ide_poll(io, true);

	for (uint32_t i = 0; i < 256; i++) {
		uint16_t data             = inw(io + ATA_REG_DATA);
		*(uint16_t*)(buf + i * 2) = data;
	}
	ide_400ns_delay(io);
}

void ata_read(uint8_t* buf, uint32_t lba, uint32_t numsects, ide_dev_t* dev) {
	for (uint32_t i = 0; i < numsects; i++) {
		ide_read_sector(buf, lba + i, dev);
		buf += 512;
	}
}

void ata_probe() {
	uint8_t* ide_buf = malloc(512);
	if (ide_buf == NULL) {
		error("Could not allocate memory for IDE probe");
		return;
	}
	if (!ide_identify(ATA_PRIMARY_BUS, ATA_PRIMARY_DRIVE, ide_buf)) {
		error("IDE primary master not found!");
		return;
	}
	debug("ide_identify");
	debug(&ide_buf[ATA_IDENT_MODEL]);
}

void enable_ata() {
	debug("Enabling ATA.");
	ata_probe();
	debug("ATA enabled.");
}
