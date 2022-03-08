.PHONY: all kernel debug clean format

$(CC) ?= gcc

all: build

kernel: bin/lapis.img

bin/boot.o: src/boot/boot.asm | bin
	@nasm \
		-f elf64 \
		-o $@ \
		$<

# --nmagic
#     Turn off page alignment of sections, and disable linking against shared
#     libraries.  If the output format supports Unix style magic numbers, mark
#     the output as "NMAGIC".
bin/kernel.elf: bin/boot.o bin/kernel.o | bin
	@ld \
		--nmagic \
		--output $@ \
		--script linker.ld \
		$^

# -masm=dialect
#     Output assembly instructions using selected dialect.  Also affects
#     which dialect is used for basic "asm" and extended "asm". Supported
#     choices (in dialect order) are att or intel. The default is att.
#     Darwin does not support intel.
#
# -mno-red-zone
#     Do not use a so-called "red zone" for x86-64 code.  The red zone is
#     mandated by the x86-64 ABI; it is a 128-byte area beyond the
#     location of the stack pointer that is not modified by signal or
#     interrupt handlers and therefore can be used for temporary data
#     without adjusting the stack pointer.  The flag -mno-red-zone
#     disables this red zone.
#
# -ffreestanding
#     Assert that compilation targets a freestanding environment.  This
#     implies -fno-builtin.  A freestanding environment is one in which the
#     standard library may not exist, and program startup may not
#     necessarily be at "main".  The most obvious example is an OS kernel.
#     This is equivalent to -fno-hosted.
#
# -nostdlib
#    Do not use the standard system startup files or libraries when
#    linking.  No startup files and only the libraries you specify are
#    passed to the linker, and options specifying linkage of the system
#    libraries, such as -static-libgcc or -shared-libgcc, are ignored.
#
#    The compiler may generate calls to "memcmp", "memset", "memcpy" and
#    "memmove".  These entries are usually resolved by entries in libc.
#    These entry points should be supplied through some other mechanism
#    when this option is specified.
#
# -fno-stack-protector
#     Do not use stack protection.
#
# -g
#     Produce debugging information in the operating system's native format
#     (stabs, COFF, XCOFF, or DWARF).  GDB can work with this debugging
#     information.
#
# -c
#     Compile or assemble the source files, but do not link.  The linking
#     stage simply is not done.  The ultimate output is in the form of an
#     object file for each source file.
#
# -o file
#     Place the primary output in file file.
bin/kernel.o: src/kernel/kernel.c | bin
	@$(CC) \
		-mno-red-zone \
		-masm=intel \
		-nostdlib \
		-fno-stack-protector \
		-ffreestanding \
		-g \
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
	@ld \
		--output $@ \
		--script linker.ld \
		$^

build: bin/kernel.iso

debug: bin/kernel.iso bin/kernel.dbg bin/fs.img
	./debug.sh

run: bin/kernel.iso bin/fs.img
	./run.sh

bin/kernel.iso: bin/kernel.elf grub.cfg | bin
	@mkdir -p bin/isofiles/boot/grub
	@cp $< bin/isofiles/boot/kernel.bin
	@cp grub.cfg bin/isofiles/boot/grub
	grub-mkrescue -o $@ bin/isofiles

format:
	@find src -iname '*.c' -print0 | xargs -0 -I '{}' clang-format --fcolor-diagnostics --Werror --verbose --style=file -i '{}'

dump-format-config:
	@clang-format --fcolor-diagnostics --Werror --verbose --style=file --dump-config

clean:
	@rm -rf bin
