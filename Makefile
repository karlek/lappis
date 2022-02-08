.PHONY: all kernel debug clean

all: build

kernel: bin/lapis.img

bin/boot.o: src/boot/boot.asm | bin
	nasm \
		-f elf64 \
		-o $@ \
		$<

bin/text.o: src/boot/text.asm | bin
	nasm \
		-f elf64 \
		-o $@ \
		$<

bin/boot.elf: bin/boot.o | bin
	ld \
		-n \
		-o $@ \
		-T linker.ld \
		$<

bin/kernel_entry.o: src/kernel/kernel.asm | bin
	nasm \
		-f elf64 \
		-o $@ \
		$<

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
bin/kernel.dbg: bin/kernel_entry.o bin/kernel.o | bin
	ld -o $@ -Ttext 0x1000 $^

# For build purposes.
bin/kernel.bin: bin/kernel_entry.o bin/kernel.o | bin
	ld -o $@ -Ttext 0x1000 $^ --oformat binary

bin/lapis.img: bin/boot.bin bin/kernel.bin | bin
	dd if=bin/boot.bin   of=bin/lapis.img seek=0
	dd if=bin/kernel.bin of=bin/lapis.img seek=1 conv=notrunc

build: bin/lapis.img

debug: bin/lapis.img bin/kernel.dbg
	./debug.sh

run: bin/lapis.img
	./run.sh

bin/kernel.iso: bin/boot.elf grub.cfg | bin
	@mkdir -p bin/isofiles/boot/grub
	@cp -v $< bin/isofiles/boot/kernel.bin
	@cp -v grub.cfg bin/isofiles/boot/grub
	@grub-mkrescue -o $@ bin/isofiles

clean:
	rm -rf bin
