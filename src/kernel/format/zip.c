#include "zip.h"

void read(uint8_t* buf, uint64_t n, uint64_t* cur, uint8_t* dest) {
	memcpy(dest, buf + *cur, n);
	(*cur) += n;
}

uint16_t read_uint16(uint8_t* buf, uint64_t* cur) {
	uint8_t raw[2] = {0};
	read(buf, sizeof raw, cur, raw);
	return raw[0] | (raw[1] << 8);
}

uint32_t read_uint32(uint8_t* buf, uint64_t* cur) {
	uint8_t raw[4] = {0};
	read(buf, sizeof raw, cur, raw);
	return raw[0] | (raw[1] << 8) | (raw[2] << 16) | (raw[3] << 24);
}

bool read_local_file(uint8_t* buf, uint64_t* cur, file_t* file) {
	uint8_t version[2] = {0};
	read(buf, sizeof version, cur, version);

	uint8_t flags[2] = {0};
	read(buf, sizeof flags, cur, flags);

	uint8_t compression_method[2] = {0};
	read(buf, sizeof compression_method, cur, compression_method);

	uint8_t last_mod_date[2] = {0};
	read(buf, sizeof last_mod_date, cur, last_mod_date);

	uint8_t last_mod_time[2] = {0};
	read(buf, sizeof last_mod_time, cur, last_mod_time);

	uint8_t crc32_uncompressed[4] = {0};
	read(buf, sizeof crc32_uncompressed, cur, crc32_uncompressed);

	uint32_t compressed_size   = read_uint32(buf, cur);
	uint32_t uncompressed_size = read_uint32(buf, cur);

	uint16_t file_name_length   = read_uint16(buf, cur);
	uint16_t extra_field_length = read_uint16(buf, cur);

	uint8_t* file_name = malloc(file_name_length + 1);
	if (file_name == NULL) {
		error("malloc failed");
		return false;
	}
	read(buf, file_name_length, cur, file_name);
	file_name[file_name_length] = 0;

	uint8_t* extra_fields = malloc(extra_field_length);
	if (extra_fields == NULL) {
		error("malloc failed");
		return false;
	}
	read(buf, extra_field_length, cur, extra_fields);

	uint8_t* uncompressed = malloc(uncompressed_size);
	if (uncompressed == NULL) {
		error("malloc failed");
		return false;
	}
	read(buf, uncompressed_size, cur, uncompressed);

	file->name = file_name;
	file->data = uncompressed;
	file->size = uncompressed_size;
	return true;
}

bool read_central_directory(uint8_t* buf, uint64_t* cur) {
	uint8_t version_made_by[2] = {0};
	read(buf, sizeof version_made_by, cur, version_made_by);

	uint8_t version_needed[2] = {0};
	read(buf, sizeof version_needed, cur, version_needed);

	uint8_t flags[2] = {0};
	read(buf, sizeof flags, cur, flags);

	uint8_t compression_method[2] = {0};
	read(buf, sizeof compression_method, cur, compression_method);

	uint8_t last_mod_date[2] = {0};
	read(buf, sizeof last_mod_date, cur, last_mod_date);

	uint8_t last_mod_time[2] = {0};
	read(buf, sizeof last_mod_time, cur, last_mod_time);

	uint8_t crc32_uncompressed[4] = {0};
	read(buf, sizeof crc32_uncompressed, cur, crc32_uncompressed);

	uint32_t compressed_size   = read_uint32(buf, cur);
	uint32_t uncompressed_size = read_uint32(buf, cur);

	uint16_t file_name_length = read_uint16(buf, cur);

	uint16_t extra_field_length  = read_uint16(buf, cur);
	uint16_t file_comment_length = read_uint16(buf, cur);

	uint16_t disk_number_start_raw = read_uint16(buf, cur);

	uint16_t internal_file_attributes = read_uint16(buf, cur);

	uint32_t external_file_attributes = read_uint32(buf, cur);

	uint32_t relative_offset_of_local_header = read_uint32(buf, cur);

	uint8_t* file_name = malloc(file_name_length + 1);
	if (file_name == NULL) {
		error("malloc failed");
		return false;
	}
	read(buf, file_name_length, cur, file_name);
	file_name[file_name_length] = 0;

	uint8_t* extra_fields = malloc(extra_field_length);
	if (extra_fields == NULL) {
		error("malloc failed");
		return false;
	}
	read(buf, extra_field_length, cur, extra_fields);

	uint8_t* file_comment = malloc(file_comment_length);
	if (file_comment == NULL) {
		error("malloc failed");
		return false;
	}
	read(buf, file_comment_length, cur, file_comment);

	return true;
}

bool read_end_of_central_directory(uint8_t* buf, uint64_t* cur) {
	uint16_t disk_number = read_uint16(buf, cur);
	uint16_t disk_number_with_start_of_central_directory =
		read_uint16(buf, cur);
	uint16_t number_of_central_directory_entries_on_this_disk =
		read_uint16(buf, cur);
	uint16_t number_of_central_directory_entries = read_uint16(buf, cur);
	uint32_t size_of_central_directory           = read_uint32(buf, cur);
	uint32_t
		offset_of_start_of_central_directory_with_respect_to_starting_disk_number =
			read_uint32(buf, cur);
	uint16_t zip_file_comment_length = read_uint16(buf, cur);

	uint8_t* zip_file_comment = malloc(zip_file_comment_length);
	if (zip_file_comment == NULL) {
		error("malloc failed");
		return false;
	}
	read(buf, zip_file_comment_length, cur, zip_file_comment);
	return true;
}

bool is_local_file_header(const uint8_t* section_type) {
	return section_type[0] == 0x03 && section_type[1] == 0x04;
}

bool is_central_directory(const uint8_t* section_type) {
	return section_type[0] == 0x01 && section_type[1] == 0x02;
}

bool is_end_of_central_directory(const uint8_t* section_type) {
	return section_type[0] == 0x05 && section_type[1] == 0x06;
}

void peek_local_file(uint8_t* buf, uint64_t* cur) {
	// version
	*cur += 2;
	// flag
	*cur += 2;
	// compression method
	*cur += 2;
	// last mod date
	*cur += 2;
	// last mod time
	*cur += 2;
	// crc32
	*cur += 4;
	// compressed size
	*cur += 4;

	uint32_t uncompressed_size  = read_uint32(buf, cur);
	uint16_t file_name_length   = read_uint16(buf, cur);
	uint16_t extra_field_length = read_uint16(buf, cur);

	*cur += file_name_length;
	*cur += extra_field_length;
	*cur += uncompressed_size;
}

void peek_central_directory(uint8_t* buf, uint64_t* cur) {
	// version made by
	*cur += 2;
	// version needed
	*cur += 2;
	// flags
	*cur += 2;
	// compression method
	*cur += 2;
	// last mod date
	*cur += 2;
	// last mod time
	*cur += 2;
	// crc32 uncompressed
	*cur += 4;
	// compressed size
	*cur += 4;
	// uncompressed size
	*cur += 4;
	// file name length
	uint16_t file_name_length = read_uint16(buf, cur);
	// extra field length
	uint16_t extra_field_length = read_uint16(buf, cur);
	// file comment length
	uint16_t file_comment_length = read_uint16(buf, cur);
	// disk number start
	*cur += 2;
	// internal file attributes
	*cur += 2;
	// external file attributes
	*cur += 4;
	// relative offset of local header
	*cur += 4;

	*cur += file_name_length;
	*cur += extra_field_length;
	*cur += file_comment_length;
}
	
void peek_end_of_central_directory(uint8_t* buf, uint64_t* cur) {
	// disk number
	*cur += 2;
	// disk number with start of central directory
	*cur += 2;
	// number of central directory entries on this disk
	*cur += 2;
	// number of central directory entries
	*cur += 2;
	// size of central directory
	*cur += 4;
	// offset of start of central directory with respect to starting disk number
	*cur += 4;
	// zip file comment length
	uint16_t zip_file_comment_length = read_uint16(buf, cur);
	*cur += zip_file_comment_length;
}

uint64_t peek_zip(uint8_t* buf) {
	uint64_t cur = 0;
	for (;;) {
		uint8_t magic[2] = {0};
		read(buf, 2, &cur, magic);
		if (magic[0] != 0x50 || magic[1] != 0x4b) {
			error("Invalid zip file. Unknown magic: %x%x", magic[0], magic[1]);
			debug_buffer(magic, 2);
			return 0;
		}

		uint8_t section_type[2] = {0};
		read(buf, 2, &cur, section_type);
		if (is_local_file_header(section_type)) {
			peek_local_file(buf, &cur);
		} else if (is_central_directory(section_type)) {
			peek_central_directory(buf, &cur);
		} else if (is_end_of_central_directory(section_type)) {
			peek_end_of_central_directory(buf, &cur);
			// We are done!
			return cur;
		} else {
			error("Invalid zip file. Unknown section type: %x%x", section_type[0], section_type[1]);
			debug_buffer(section_type, 2);
			return 0;
		}
	}
}

void read_zip(uint8_t* buf, uint64_t len, zip_fs_t* zipfs) {
	file_t** files = malloc(16 * sizeof(file_t*));
	if (files == NULL) {
		error("malloc failed");
		return;
	}
	zipfs->files   = files;

	uint32_t num_files = 0;

	uint64_t cur = 0;
	while (cur < len) {
		uint8_t magic[2] = {0};
		read(buf, 2, &cur, magic);
		if (magic[0] != 0x50 || magic[1] != 0x4b) {
			error("Invalid zip file!");
			debug_buffer(magic, 2);
			return;
		}

		uint8_t section_type[2] = {0};
		read(buf, 2, &cur, section_type);
		if (is_local_file_header(section_type)) {
			file_t* file = malloc(sizeof(file_t));
			if (file == NULL) {
				error("malloc failed");
				return;
			}
			if (read_local_file(buf, &cur, file) == false) {
				error("Failed to read local file header");
				return;
			}
			zipfs->files[num_files] = file;
			num_files++;
		} else if (is_central_directory(section_type)) {
			if (read_central_directory(buf, &cur) == false) {
				error("Unable to read central directory");
				return;
			}
		} else if (is_end_of_central_directory(section_type)) {
			if (read_end_of_central_directory(buf, &cur) == false) {
				error("Unable to read end of central directory");
				return;
			}
			// We are done!
			break;
		} else {
			error("Invalid zip file!");
			debug_buffer(section_type, 2);
			return;
		}
	}
	zipfs->num_files = num_files;
}
