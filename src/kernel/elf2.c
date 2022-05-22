#include "elf2.h"

/* void read(uint8_t* buf, uint64_t n, uint64_t* cur, uint8_t* dest) { */
/* 	memcpy(dest, buf + *cur, n); */
/* 	(*cur) += n; */
/* } */

uint8_t read_uint8(uint8_t* buf, uint64_t* cur) {
	uint8_t raw[1] = {0};
	read(buf, sizeof raw, cur, raw);
	return raw[0];
}

uint64_t read_uint64(uint8_t* buf, uint64_t* cur) {
	uint8_t raw[8] = {0};
	read(buf, sizeof raw, cur, raw);
	uint64_t ret = 0;

	for (int i = 7; i >= 0; i--) {
		ret = (ret << 8) | raw[i];
	}
	return ret;
}

/* uint16_t read_uint16(uint8_t* buf, uint64_t* cur) { */
/* 	uint8_t raw[2] = {0}; */
/* 	read(buf, sizeof raw, cur, raw); */
/* 	return raw[0] | (raw[1] << 8); */
/* } */

/* uint32_t read_uint32(uint8_t* buf, uint64_t* cur) { */
/* 	uint8_t raw[4] = {0}; */
/* 	read(buf, sizeof raw, cur, raw); */
/* 	return raw[0] | (raw[1] << 8) | (raw[2] << 16) | (raw[3] << 24); */
/* } */

void parse_ident(uint8_t* userland_obj, uint64_t* cur, uint8_t* e_ident) {
	uint8_t magic[4] = {0};
	read(userland_obj, 4, cur, magic);
	debug("ELF magic: %x %x %x %x", magic[0], magic[1], magic[2], magic[3]);
	debug("ELF magic: %x %x %x %x", ELFMAG0, ELFMAG1, ELFMAG2, ELFMAG3);
	if (streqn(magic, ELFMAG, 4)) {
		debug("magic is valid");
	}
	e_ident[EI_MAG0] = magic[0];
	e_ident[EI_MAG1] = magic[1];
	e_ident[EI_MAG2] = magic[2];
	e_ident[EI_MAG3] = magic[3];

	uint8_t bitness = read_uint8(userland_obj, cur);
	debug("ELF class (bitness): %d", bitness);
	if (bitness != ELFCLASS64) {
		debug("not implemented!");
		return;
	}
	e_ident[EI_CLASS] = bitness;

	uint8_t endianess = read_uint8(userland_obj, cur);
	debug("ELF endianess: %d", endianess);
	e_ident[EI_DATA] = endianess;

	uint8_t elf_version = read_uint8(userland_obj, cur);
	debug("ELF version: %d", elf_version);
	e_ident[EI_VERSION] = elf_version;

	uint8_t os_abi = read_uint8(userland_obj, cur);
	debug("ELF os_abi: %d", os_abi);
	e_ident[EI_OSABI] = os_abi;

	uint8_t abi_version = read_uint8(userland_obj, cur);
	debug("ELF abi_version: %d", abi_version);
	e_ident[EI_ABIVERSION] = abi_version;

	uint8_t padding[7] = {0};
	read(userland_obj, 7, cur, padding);
	debug("ELF padding: %x %x %x %x %x %x %x", padding[0], padding[1], padding[2], padding[3], padding[4], padding[5], padding[6]);
}

Elf64_Ehdr *parse_elf_header(uint8_t* userland_obj, uint64_t* cur) {
	uint8_t* e_ident = malloc(EI_NIDENT);
	parse_ident(userland_obj, cur, e_ident);
	if (e_ident[EI_CLASS] != ELFCLASS64) {
		debug("not implemented!");
		return NULL;
	}

	Elf64_Ehdr *header = malloc(sizeof(Elf64_Ehdr));
	*header->e_ident = e_ident;

	header->e_type = read_uint16(userland_obj, cur);
	debug("ELF type: %d", header->e_type);

	header->e_machine = read_uint16(userland_obj, cur);
	debug("ELF machine: %d", header->e_machine);

	header->e_version = read_uint32(userland_obj, cur);
	debug("ELF version: %d", header->e_version);

	header->e_entry = read_uint64(userland_obj, cur);
	debug("ELF entry: 0x%llx", header->e_entry);

	header->e_phoff = read_uint64(userland_obj, cur);
	debug("ELF phoff: 0x%llx", header->e_phoff);

	header->e_shoff = read_uint64(userland_obj, cur);
	debug("ELF shoff: 0x%llx", header->e_shoff);

	header->e_flags = read_uint32(userland_obj, cur);
	debug("ELF flags: 0x%x", header->e_flags);

	header->e_ehsize = read_uint16(userland_obj, cur);
	debug("ELF ehsize: 0x%x", header->e_ehsize);

	header->e_phentsize = read_uint16(userland_obj, cur);
	debug("ELF phentsize: 0x%x", header->e_phentsize);

	header->e_phnum = read_uint16(userland_obj, cur);
	debug("ELF phnum: 0x%x", header->e_phnum);

	header->e_shentsize = read_uint16(userland_obj, cur);
	debug("ELF shentsize: 0x%x", header->e_shentsize);

	header->e_shnum = read_uint16(userland_obj, cur);
	debug("ELF qtySectionHeaders: 0x%x", header->e_shnum);

	header->e_shstrndx = read_uint16(userland_obj, cur);
	debug("ELF sectionNamesIndex: 0x%x", header->e_shstrndx);

	return header;
}

Elf64_Phdr *parse_program_segment_header(uint8_t* userland_obj, uint64_t* cur) {
	Elf64_Phdr *program_segment_header = malloc(sizeof(Elf64_Shdr));

	program_segment_header->p_type = read_uint32(userland_obj, cur);
	debug("Segment type: %d", program_segment_header->p_type);

	program_segment_header->p_flags = read_uint32(userland_obj, cur);
	debug("Segment flags: %d", program_segment_header->p_flags);

	program_segment_header->p_offset = read_uint64(userland_obj, cur);
	debug("Segment offset: 0x%llx", program_segment_header->p_offset);

	program_segment_header->p_vaddr = read_uint64(userland_obj, cur);
	debug("Segment virtual addr: 0x%llx", program_segment_header->p_vaddr);

	program_segment_header->p_paddr = read_uint64(userland_obj, cur);
	debug("Segment physical addr: 0x%llx", program_segment_header->p_paddr);

	program_segment_header->p_filesz = read_uint64(userland_obj, cur);
	debug("Segment size in file: 0x%llx", program_segment_header->p_filesz);

	program_segment_header->p_memsz = read_uint64(userland_obj, cur);
	debug("Segment size in memory: 0x%llx", program_segment_header->p_memsz);

	program_segment_header->p_align = read_uint64(userland_obj, cur);
	debug("Segment alignment: 0x%llx", program_segment_header->p_align);

	return program_segment_header;
}

Elf64_Shdr *parse_section_header(uint8_t* userland_obj, uint64_t* cur) {
	Elf64_Shdr *section_header = malloc(sizeof(Elf64_Shdr));

	section_header->sh_name = read_uint32(userland_obj, cur);
	debug("Section name: %d", section_header->sh_name);

	section_header->sh_type = read_uint32(userland_obj, cur);
	/* debug("Section type: 0x%x", section_header->sh_type); */

	section_header->sh_flags = read_uint64(userland_obj, cur);
	/* debug("Section flags: 0x%llx", section_header->sh_flags); */

	section_header->sh_addr = read_uint64(userland_obj, cur);
	/* debug("Section addr: 0x%llx", section_header->sh_addr); */

	section_header->sh_offset = read_uint64(userland_obj, cur);
	/* debug("Section offset: 0x%llx", section_header->sh_offset); */

	section_header->sh_size = read_uint64(userland_obj, cur);
	/* debug("Section size: 0x%llx", section_header->sh_size); */

	section_header->sh_link = read_uint32(userland_obj, cur);
	/* debug("Section link: 0x%x", section_header->sh_link); */

	section_header->sh_info = read_uint32(userland_obj, cur);
	/* debug("Section info: 0x%x", section_header->sh_info); */

	section_header->sh_addralign = read_uint64(userland_obj, cur);
	/* debug("Section addralign: 0x%llx", section_header->sh_addralign); */

	section_header->sh_entsize = read_uint64(userland_obj, cur);
	/* debug("Section entsize: 0x%llx", section_header->sh_entsize); */

	return section_header;
}

extern void enter_userland(void *entry_point);

void run_userland(uint8_t* userland_obj, size_t userland_obj_size) {
	uint64_t cur = 0;

	Elf64_Ehdr *header = parse_elf_header(userland_obj, &cur);
	if (header == NULL) {
		debug("header is null");
		return;
	}

	// TODO...
	uint16_t num_sections = 19;
	cur = header->e_shoff;
	for (int i = 0; i < header->e_shnum; i++) {
		Elf64_Shdr *section_header = parse_section_header(userland_obj, &cur);
	}

	cur = header->e_phoff;
	for (int i = 0; i < header->e_phnum; i++) {
		Elf64_Phdr *program_segment_header = parse_program_segment_header(userland_obj, &cur);
		if (program_segment_header->p_type != 1) {
			debug("not implemented!");
			continue;
		}
		uint64_t pseg_cur = program_segment_header->p_offset;

		debug("file size: 0x%llx", program_segment_header->p_filesz);
		debug("pseg_cur: %d", pseg_cur);
		uint8_t *code = malloc(program_segment_header->p_filesz);
		read(userland_obj, program_segment_header->p_filesz, &pseg_cur, code);
		debug("pseg_cur: %d", pseg_cur);
		debug_buffer(code, program_segment_header->p_filesz);

		code += header->e_entry-program_segment_header->p_paddr;
		enter_userland(code);
		return;
	}
}
