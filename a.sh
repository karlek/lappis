#!/bin/bash

set -e

# sudo systemctl start docker
mkdir -p bin

nasm \
	-f bin \
	-o bin/boot.bin \
	src/boot.asm

nasm \
	-f elf64 \
	-o bin/kernel_entry.o \
	src/kernel.asm

gcc \
	-g \
	-nostdlib \
	-ffreestanding \
	-c src/kernel.c \
	-o bin/kernel.o

# For debug symbols.
ld -o bin/kernel.dbg -Ttext 0x1000 bin/kernel_entry.o bin/kernel.o
# For build purposes.
ld -o bin/kernel.bin -Ttext 0x1000 bin/kernel_entry.o bin/kernel.o --oformat binary

dd if=bin/boot.bin   of=bin/lapis.img seek=0
dd if=bin/kernel.bin of=bin/lapis.img seek=1 conv=notrunc

# -S     Do not start CPU at startup (you must type 'c' in the monitor).
qemu-system-x86_64 \
	-S \
	-gdb tcp::1234 \
	-fda bin/lapis.img &

gdb \
	--quiet \
	-ex 'target remote localhost:1234' \
	-ex 'symbol-file bin/kernel.dbg' \
	-ex 'break main' \
	-ex 'continue'
	# -ex 'quit'

	
	# -ex 'continue' \
# qemu-system-x86_64 -drive file=bin/lapis.img,format=raw
# docker build -t lapis .
# docker run -it lapis
