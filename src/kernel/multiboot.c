/* struct multiboot_tag { */
/*     uint32_t type; */
/*     uint32_t size; */
/* }; */

struct multiboot_info {
    uint32_t total_size;
    uint32_t reserved;
    struct multiboot_tag tags[0];
};

unsigned char* get_tag_name(int tag_type) {
	switch (tag_type) {
		case 0: {return "MULTIBOOT_TAG_TYPE_END";}
		case 1: {return "MULTIBOOT_TAG_TYPE_CMDLINE";}
		case 2: {return "MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME";}
		case 3: {return "MULTIBOOT_TAG_TYPE_MODULE";}
		case 4: {return "MULTIBOOT_TAG_TYPE_BASIC_MEMINFO";}
		case 5: {return "MULTIBOOT_TAG_TYPE_BOOTDEV";}
		case 6: {return "MULTIBOOT_TAG_TYPE_MMAP";}
		case 7: {return "MULTIBOOT_TAG_TYPE_VBE";}
		case 8: {return "MULTIBOOT_TAG_TYPE_FRAMEBUFFER";}
		case 9: {return "MULTIBOOT_TAG_TYPE_ELF_SECTIONS";}
		case 10: {return "MULTIBOOT_TAG_TYPE_APM";}
		case 11: {return "MULTIBOOT_TAG_TYPE_EFI32";}
		case 12: {return "MULTIBOOT_TAG_TYPE_EFI64";}
		case 13: {return "MULTIBOOT_TAG_TYPE_SMBIOS";}
		case 14: {return "MULTIBOOT_TAG_TYPE_ACPI_OLD";}
		case 15: {return "MULTIBOOT_TAG_TYPE_ACPI_NEW";}
		case 16: {return "MULTIBOOT_TAG_TYPE_NETWORK";}
		case 17: {return "MULTIBOOT_TAG_TYPE_EFI_MMAP";}
		case 18: {return "MULTIBOOT_TAG_TYPE_EFI_BS";}
		case 19: {return "MULTIBOOT_TAG_TYPE_EFI32_IH";}
		case 20: {return "MULTIBOOT_TAG_TYPE_EFI64_IH";}
		case 21: {return "MULTIBOOT_TAG_TYPE_LOAD_BASE_ADDR";}
		default:
			return "Unknown";
	}
}

/* int i = 0; */
/* struct multiboot_tag *tag = boot_info->tags; */
/* while (tag->type != 0) { */
/* 	switch (tag->type) { */
/* 		default: */
/* 			unsigned int next = ((tag->size+8) / 8); */
/* 			printf("Skipping: %s\n", 300, 300+i*LARGE_FONT_CELL_HEIGHT, NULL, get_tag_name(tag->type)); */
/* 			tag += next; */
/* 	} */
/* 	i++; */
/* } */
