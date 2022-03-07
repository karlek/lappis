.PHONY: all kernel debug clean

all: build

kernel: bin/lapis.img

bin/boot.o: src/boot/boot.asm | bin
	@nasm \
		-f elf64 \
		-o $@ \
		$<

bin/kernel.elf: bin/boot.o bin/kernel.o | bin
	@ld \
		-n \
		-o $@ \
		-T linker.ld \
		$^

bin/kernel.o: src/kernel/kernel.c | bin
	@gcc \
		-mno-red-zone \
		-masm=intel \
		-g \
		-nostdlib \
		-fno-stack-protector \
		-ffreestanding \
		-c $< \
		-o $@

bin/zipfs.zip: bin/nested.zip | bin
	zip -0 -r $@ $<

bin/nested.zip: | bin
	zip -0 -r $@ zipfs

bin/fs.img: bin/zipfs.zip | bin
	dd if=bin/zipfs.zip of=$@ bs=1M conv=sync

bin:
	@mkdir -p $@

# For debug symbols.
bin/kernel.dbg: bin/boot.o bin/kernel.o | bin
	@ld -o $@ -T linker.ld $^

build: bin/kernel.iso

debug: bin/kernel.iso bin/kernel.dbg bin/fs.img
	./debug.sh

run: bin/kernel.iso bin/fs.img
	./run.sh

bin/kernel.iso: bin/kernel.elf grub.cfg | bin
	@mkdir -p bin/isofiles/boot/grub
	@cp $< bin/isofiles/boot/kernel.bin
	@cp grub.cfg bin/isofiles/boot/grub
	@grub-mkrescue -o $@ bin/isofiles 2> /dev/null

clean:
	@rm -rf bin
