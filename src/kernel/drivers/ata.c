extern void ata_handler() {
	printf("ATA interrupt!", 0, 400, NULL);
}

void enable_ata() {
	printf("Enabling ATA interrupt...", 0, 450, NULL);
}
