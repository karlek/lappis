typedef struct zip_t {
	uint8_t signature[4];
	uint8_t version[2];
	uint8_t flags[2];
	uint8_t compression_method[2];
	uint8_t last_mod_time[2];
	uint8_t last_mod_date[2];
	uint8_t crc32[4];
	uint32_t compressed_size;
	uint32_t uncompressed_size;
	uint16_t file_name_length;
	uint16_t extra_field_length;
	uint8_t *file_name;
	uint8_t *extra_fields;
	uint8_t *uncompressed;
} zip_t;

void read(uint8_t* buf, int n, uint32_t* cur, uint8_t* dest) {
	for (int i = 0; i < n; i++) {
		dest[i] = buf[(*cur)++];
	}
}

void read_zip(uint8_t *buf, uint32_t* cur, zip_t *zip) {
	uint8_t signature[4] = {0};
	read(buf, sizeof signature, cur, signature);

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

	uint8_t compressed_size[4] = {0};
	read(buf, sizeof compressed_size, cur, compressed_size);

	uint8_t uncompressed_size_raw[4] = {0};
	read(buf, sizeof uncompressed_size_raw, cur, uncompressed_size_raw);
	uint32_t uncompressed_size = uncompressed_size_raw[0] | (uncompressed_size_raw[1] << 8) | (uncompressed_size_raw[2] << 16) | (uncompressed_size_raw[3] << 24);

	uint8_t file_name_length_raw[2] = {0};
	read(buf, sizeof file_name_length_raw, cur, file_name_length_raw);
	uint16_t file_name_length = file_name_length_raw[0] | (file_name_length_raw[1] << 8);

	uint8_t extra_field_length_raw[2] = {0};
	read(buf, sizeof extra_field_length_raw, cur, extra_field_length_raw);
	uint16_t extra_field_length = extra_field_length_raw[0] | (extra_field_length_raw[1] << 8);

	// 256 is aribtrary. Use malloc when it exists.
	static uint8_t file_name[256] = {0};
	read(buf, file_name_length, cur, file_name);

	// 256 is aribtrary. Use malloc when it exists.
	uint8_t extra_fields[256] = {0};
	read(buf, extra_field_length, cur, extra_fields);

	uint8_t uncompressed[256] = {0};
	read(buf, uncompressed_size, cur, uncompressed);

	zip->signature[0] = signature[0];
	zip->signature[1] = signature[1];
	zip->signature[2] = signature[2];
	zip->signature[3] = signature[3];
	zip->version[0] = version[0];
	zip->version[1] = version[1];
	zip->flags[0] = flags[0];
	zip->flags[1] = flags[1];
	zip->compression_method[0] = compression_method[0];
	zip->compression_method[1] = compression_method[1];
	zip->last_mod_date[0] = last_mod_date[0];
	zip->last_mod_date[1] = last_mod_date[1];
	zip->last_mod_time[0] = last_mod_time[0];
	zip->last_mod_time[1] = last_mod_time[1];
	zip->crc32[0] = crc32_uncompressed[0];
	zip->crc32[1] = crc32_uncompressed[1];
	zip->crc32[2] = crc32_uncompressed[2];
	zip->crc32[3] = crc32_uncompressed[3];
	zip->compressed_size = compressed_size;
	zip->uncompressed_size = uncompressed_size;
	zip->file_name_length = file_name_length;
	zip->extra_field_length = extra_field_length;
	zip->file_name = file_name;
	zip->extra_fields = extra_fields;
	zip->uncompressed = uncompressed;
}
