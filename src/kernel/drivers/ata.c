#define ATA_SR_BSY  0x80
#define ATA_SR_DRDY 0x40
#define ATA_SR_DF   0x20
#define ATA_SR_DSC  0x10
#define ATA_SR_DRQ  0x08
#define ATA_SR_CORR 0x04
#define ATA_SR_IDX  0x02
#define ATA_SR_ERR  0x01

#define ATA_ER_BBK   0x80
#define ATA_ER_UNC   0x40
#define ATA_ER_MC    0x20
#define ATA_ER_IDNF  0x10
#define ATA_ER_MCR   0x08
#define ATA_ER_ABRT  0x04
#define ATA_ER_TK0NF 0x02
#define ATA_ER_AMNF  0x01

#define ATA_CMD_READ_PIO        0x20
#define ATA_CMD_READ_PIO_EXT    0x24
#define ATA_CMD_READ_DMA        0xC8
#define ATA_CMD_READ_DMA_EXT    0x25
#define ATA_CMD_WRITE_PIO       0x30
#define ATA_CMD_WRITE_PIO_EXT   0x34
#define ATA_CMD_WRITE_DMA       0xCA
#define ATA_CMD_WRITE_DMA_EXT   0x35
#define ATA_CMD_CACHE_FLUSH     0xE7
#define ATA_CMD_CACHE_FLUSH_EXT 0xEA
#define ATA_CMD_PACKET          0xA0
#define ATA_CMD_IDENTIFY_PACKET 0xA1
#define ATA_CMD_IDENTIFY        0xEC

#define ATAPI_CMD_READ  0xA8
#define ATAPI_CMD_EJECT 0x1B

#define ATA_IDENT_DEVICETYPE   0
#define ATA_IDENT_CYLINDERS    2
#define ATA_IDENT_HEADS        6
#define ATA_IDENT_SECTORS      12
#define ATA_IDENT_SERIAL       20
#define ATA_IDENT_MODEL        54
#define ATA_IDENT_CAPABILITIES 98
#define ATA_IDENT_FIELDVALID   106
#define ATA_IDENT_MAX_LBA      120
#define ATA_IDENT_COMMANDSETS  164
#define ATA_IDENT_MAX_LBA_EXT  200

#define IDE_ATA   0x00
#define IDE_ATAPI 0x01

#define ATA_PRIMARY_DRIVE   0x00
#define ATA_SECONDARY_DRIVE 0x01

#define ATA_REG_DATA       0x00
#define ATA_REG_ERROR      0x01
#define ATA_REG_FEATURES   0x01
#define ATA_REG_SECCOUNT0  0x02
#define ATA_REG_LBA0       0x03
#define ATA_REG_LBA1       0x04
#define ATA_REG_LBA2       0x05
#define ATA_REG_HDDEVSEL   0x06
#define ATA_REG_COMMAND    0x07
#define ATA_REG_STATUS     0x07
#define ATA_REG_SECCOUNT1  0x08
#define ATA_REG_LBA3       0x09
#define ATA_REG_LBA4       0x0A
#define ATA_REG_LBA5       0x0B
#define ATA_REG_CONTROL    0x0C
#define ATA_REG_ALTSTATUS  0x0C
#define ATA_REG_DEVADDRESS 0x0D

// Channels:
#define ATA_PRIMARY_BUS   0x00
#define ATA_SECONDARY_BUS 0x01

// Directions:
#define ATA_READ  0x00
#define ATA_WRITE 0x013

#define ATA_PRIMARY_IO   0x1F0
#define ATA_SECONDARY_IO 0x170

#define ATA_PRIMARY_IRQ   14
#define ATA_SECONDARY_IRQ 15

typedef struct ide_dev {
	uint8_t  bus;
	uint8_t  drive;
	uint16_t io;
} ide_dev;

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

	while (inb(io + ATA_REG_STATUS) & ATA_SR_BSY != 0) {}
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
		error("Unknown IDE error. TODO: implement IDE error handling");
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

void ide_read_sector(uint8_t* buf, uint32_t lba, ide_dev* dev) {
	uint8_t  drive = dev->drive;
	uint16_t io    = dev->io;

	bool    is_primary    = drive == ATA_PRIMARY_DRIVE;
	uint8_t command       = is_primary ? 0xE0 : 0xF0;
	uint8_t secondary_bit = !is_primary;

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

void ata_read(uint8_t* buf, uint32_t lba, uint32_t numsects, ide_dev* dev) {
	for (uint32_t i = 0; i < numsects; i++) {
		ide_read_sector(buf, lba + i, dev);
		buf += 512;
	}
}

void ata_probe() {
	uint8_t* ide_buf = malloc(512);
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
