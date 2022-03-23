#include "multiboot.h"

struct multiboot_info {
	uint32_t             total_size;
	uint32_t             reserved;
	struct multiboot_tag tags[0];
};

uint8_t* get_tag_name(uint8_t tag_type) {
	switch (tag_type) {
	case 0:
		return "MULTIBOOT_TAG_TYPE_END";
	case 1:
		return "MULTIBOOT_TAG_TYPE_CMDLINE";
	case 2:
		return "MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME";
	case 3:
		return "MULTIBOOT_TAG_TYPE_MODULE";
	case 4:
		return "MULTIBOOT_TAG_TYPE_BASIC_MEMINFO";
	case 5:
		return "MULTIBOOT_TAG_TYPE_BOOTDEV";
	case 6:
		return "MULTIBOOT_TAG_TYPE_MMAP";
	case 7:
		return "MULTIBOOT_TAG_TYPE_VBE";
	case 8:
		return "MULTIBOOT_TAG_TYPE_FRAMEBUFFER";
	case 9:
		return "MULTIBOOT_TAG_TYPE_ELF_SECTIONS";
	case 10:
		return "MULTIBOOT_TAG_TYPE_APM";
	case 11:
		return "MULTIBOOT_TAG_TYPE_EFI32";
	case 12:
		return "MULTIBOOT_TAG_TYPE_EFI64";
	case 13:
		return "MULTIBOOT_TAG_TYPE_SMBIOS";
	case 14:
		return "MULTIBOOT_TAG_TYPE_ACPI_OLD";
	case 15:
		return "MULTIBOOT_TAG_TYPE_ACPI_NEW";
	case 16:
		return "MULTIBOOT_TAG_TYPE_NETWORK";
	case 17:
		return "MULTIBOOT_TAG_TYPE_EFI_MMAP";
	case 18:
		return "MULTIBOOT_TAG_TYPE_EFI_BS";
	case 19:
		return "MULTIBOOT_TAG_TYPE_EFI32_IH";
	case 20:
		return "MULTIBOOT_TAG_TYPE_EFI64_IH";
	case 21:
		return "MULTIBOOT_TAG_TYPE_LOAD_BASE_ADDR";
	default:
		return "Unknown";
	}
}

void parse_multiboot_header(multiboot_info_t* boot_info) {
	struct multiboot_tag *tag = boot_info->tags;

	uint32_t travel = 0;
	for ( ;; ) {
		debug("Type: %s", get_tag_name(tag->type));
		if (tag->type == MULTIBOOT_TAG_TYPE_END && tag->size == 8) {
			break;
		}
		if (travel > boot_info->total_size) {
			error("Traveled too far, aborting! (travel: %d, total_size: %d)", travel, boot_info->total_size);
			break;
		}

		switch (tag->type) {
			case MULTIBOOT_TAG_TYPE_CMDLINE: {
				multiboot_tag_string_t* cmdline = (multiboot_tag_string_t*)tag;
				debug("\tCmdline: %s", cmdline->string);
				break;
			}
			case MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME: {
				multiboot_tag_string_t* boot_loader_name = (multiboot_tag_string_t*)tag;
				debug("\tBoot loader name: %s", boot_loader_name->string);
				break;
			}
			case MULTIBOOT_TAG_TYPE_BASIC_MEMINFO: {
				multiboot_tag_basic_meminfo_t* meminfo = (multiboot_tag_basic_meminfo_t*)tag;
				debug("\tMemory: %dKB/%dKB", meminfo->mem_lower, meminfo->mem_upper);
				break;
			}
			case MULTIBOOT_TAG_TYPE_BOOTDEV: {
				multiboot_tag_bootdev_t* bootdev = (multiboot_tag_bootdev_t*)tag;
				debug("\tBoot device: %d:%d", bootdev->biosdev, bootdev->slice);
				break;
			}
			case MULTIBOOT_TAG_TYPE_MMAP: {
				multiboot_tag_mmap_t* mmap = (multiboot_tag_mmap_t*)tag;
				debug("\tMemory map: %x", mmap->entry_size);
				break;
			}
			case MULTIBOOT_TAG_TYPE_VBE: {
				multiboot_tag_vbe_t* vbe = (multiboot_tag_vbe_t*)tag;
				debug("\tVBE: %d", vbe->vbe_mode);
				break;
			}
			case MULTIBOOT_TAG_TYPE_FRAMEBUFFER: {
				multiboot_tag_framebuffer_t* framebuffer = (multiboot_tag_framebuffer_t*)tag;
				debug("\tFramebuffer: %d x %d, %d bpp", framebuffer->common.framebuffer_width, framebuffer->common.framebuffer_height, framebuffer->common.framebuffer_bpp);
				break;
			}
			case MULTIBOOT_TAG_TYPE_ELF_SECTIONS: {
				multiboot_tag_elf_sections_t* elf_sections = (multiboot_tag_elf_sections_t*)tag;
				debug("\tELF sections: %x", elf_sections->num);
				break;
			}
			case MULTIBOOT_TAG_TYPE_APM: {
				multiboot_tag_apm_t* apm = (multiboot_tag_apm_t*)tag;
				debug("\tAPM info: %x", apm->version);
				break;
			}
			case MULTIBOOT_TAG_TYPE_ACPI_OLD: {
				multiboot_tag_old_acpi_t* acpi = (multiboot_tag_old_acpi_t*)tag;
				debug("\tACPI: %x (%d bytes)", acpi->rsdp.RsdtAddress, acpi->size);
				break;
			}
			case MULTIBOOT_TAG_TYPE_LOAD_BASE_ADDR: {
				multiboot_tag_load_base_addr_t* base_addr = (multiboot_tag_load_base_addr_t*)tag;
				debug("\tBase address: %x", base_addr->load_base_addr);
				break;
			}
			default: {
				error("Unknown tag: %d", tag->type);
				break;
			}
		}

		uint32_t next = tag->size % 8 == 0 ? (tag->size / 8) : (tag->size+8) / 8;
		travel += next*sizeof(struct multiboot_tag);
		tag += next;
	}
}
