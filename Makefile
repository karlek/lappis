.PHONY: all kernel debug clean

all: build

kernel: bin/lapis.img

bin/boot.o: src/boot/boot.asm | bin
	nasm \
		-f elf64 \
		-o $@ \
		$<

bin/kernel.elf: bin/boot.o bin/kernel.o | bin
	ld \
		-n \
		-o $@ \
		-T linker.ld \
		$^

bin/kernel.o: src/kernel/kernel.c | bin
	gcc \
		-masm=intel \
		-g \
		-nostdlib \
		-fno-stack-protector \
		-ffreestanding \
		-c $< \
		-o $@

bin:
	mkdir -p $@

# For debug symbols.
bin/kernel.dbg: bin/boot.o bin/kernel.o | bin
	ld -o $@ -T linker.ld $^

build: bin/kernel.iso

debug: bin/kernel.iso bin/kernel.dbg
	./debug.sh

run: bin/kernel.iso
	./run.sh

bin/kernel.iso: bin/kernel.elf grub.cfg | bin
	@mkdir -p bin/isofiles/boot/grub
	@cp -v $< bin/isofiles/boot/kernel.bin
	@cp -v grub.cfg bin/isofiles/boot/grub
	@grub-mkrescue -o $@ bin/isofiles 2> /dev/null

clean:
	rm -rf bin
