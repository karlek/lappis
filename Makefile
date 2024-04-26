.PHONY: all kernel debug clean format

CC := clang

all: build

kernel: bin/lappis.img

bin/boot.o: src/boot/*.asm | bin
	@nasm \
		-f elf64 \
		-o $@ \
		$<

bin/kernel-userland.o: src/kernel/userland.asm | bin
	@nasm \
		-f elf64 \
		-o $@ \
		$<

# NOTE: use `-fcompiler-rt` to include __zig_probe_stack symbol when linking
# (see https://github.com/ziglang/zig/issues/6817).
bin/%_32_zig.o: src/boot/%_32.zig | bin
	zig build-obj \
		--cache-dir bin/zig-cache \
		-I src/kernel \
		-mno-red-zone \
		-fcompiler-rt \
		-static \
		-target x86-freestanding-gnu \
		-O Debug \
		-mcpu=i386 \
		-femit-bin=$@ \
		$<

# TODO: remove objcopy hack when we figure out a way to emit ELF64 objets
# containing 32-bit code in Zig (NOTE: how is this done in C??).
bin/%_elf64_zig.o: bin/%_32_zig.o
	@objcopy --output-target elf64-x86-64 $< $@

# --nmagic
#     Turn off page alignment of sections, and disable linking against shared
#     libraries.  If the output format supports Unix style magic numbers, mark
#     the output as "NMAGIC".
#
# TODO: When ubuntu-latest on github actions is updated, add this to remove nag.
# --no-warn-rwx-segments
#     Allow use of RWX segments.

# NOTE: using ld.lld instead of ld as work-around for bug in ld (for details,
# see https://github.com/karlek/lappis/pull/19/commits/9cf1a8a7d40c21c6a23c1bb0412a7f49f3f1b211#r883015557).
bin/kernel.elf: bin/boot_elf64_zig.o bin/paging_elf64_zig.o bin/boot.o bin/kernel-userland.o bin/kernel.o bin/libhello.o bin/libfloof.a | bin
	ld.lld \
		--nmagic \
		--output $@ \
		--script linker.ld \
		$^

# For debug symbols.
#
# TODO: When ubuntu-latest on github actions is updated, add this to remove nag.
# --no-warn-rwx-segments
#     Allow use of RWX segments.
bin/kernel.dbg: bin/boot_elf64_zig.o bin/paging_elf64_zig.o bin/boot.o bin/kernel-userland.o bin/kernel.o bin/libhello.o bin/libfloof.a | bin
	ld.lld \
		--output $@ \
		--script linker.ld \
		$^

# TODO: re-enable Intel masm dialect (-masm=intel) when Clang cpuid.h has been
# updated to support both Intel and AT&T syntax. Regression observed in Clang
# 17.0.6.

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
# -r  Produce a relocatable object as output.  This is also known as partial
#     linking.
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
bin/kernel.o: src/kernel/*.c src/kernel/*/*.c | bin
	@# -Wno-pointer-sign should be investigated in the future, right now it's
	@#  just annoying af.
	@$(CC) \
		-DLITTLE_ENDIAN \
		-DINDEXED_COPY \
		-DMEMCPY_64BIT \
		-mno-red-zone \
		-nostdlib \
		-static \
		-r \
		-I./src/kernel \
		-fno-stack-protector \
		-ffreestanding \
		-Wno-pointer-sign \
		-g \
		$^ \
		-o $@

fs/userland.elf: src/userland/*.c | bin
	@$(CC) \
		-mno-red-zone \
		-nostdlib \
		-static \
		-fno-stack-protector \
		-ffreestanding \
		-e elf_userland \
		-g \
		-T userland-linker.ld \
		$^ \
		-o bin/userland.elf
	cp bin/userland.elf $@

bin/zipfs.zip: fs/userland.elf | bin
	zip -0 -j -r $@ fs

bin/zipfs.img: bin/zipfs.zip | bin
	dd if=bin/zipfs.zip of=$@ bs=1M conv=sync

bin/fat32.img: | bin
	@dd if=/dev/zero of=$@ count=50 bs=1M conv=sync
	@mkfs.vfat -F 32 $@
	@mcopy -i $@ -s fs/* ::
	@mdir -i $@ -s

bin:
	@mkdir -p $@

bin/libhello.o: src/kernel/zig/hello.zig | bin
	@zig build-obj \
		--cache-dir bin/zig-cache \
		-I src/kernel \
		-mno-red-zone \
		-target x86_64-freestanding-gnu \
		-femit-bin=$@ \
		$<

bin/libfloof.a: src/kernel/rust/src/lib.rs
	@# make creates a sub-shell per line.
	cd src/kernel/rust; cargo build -Zbuild-std ; cargo build
	mv src/kernel/rust/target/os/debug/libfloof.a bin

build: bin/kernel.iso bin/kernel.dbg bin/zipfs.img

debug: bin/kernel.iso bin/kernel.dbg bin/zipfs.img bin/fat32.img
	./debug.sh

run: bin/kernel.iso bin/zipfs.img bin/fat32.img
	./run.sh

bin/kernel.iso: bin/kernel.elf grub.cfg | bin
	@mkdir -p bin/isofiles/boot/grub
	@cp $< bin/isofiles/boot/kernel.bin
	@cp grub.cfg bin/isofiles/boot/grub
	grub-mkrescue -o $@ bin/isofiles

format:
	@find src -iname '*.c' -print0 | xargs -0 -I '{}' clang-format --fcolor-diagnostics --Werror --verbose --style=file -i '{}'

lint:
	@find . -iname '*.c' ! -path './tools/*' | grep -v -x -f ./.clang-tidy-ignore | xargs -I '{}' clang-tidy \
		-format-style=file \
		--extra-arg="-I./src/kernel" \
		--use-color \
		--quiet \
		-header-filter='.*' \
		-checks="modernize-*,readability-*,performance-*,-readability-magic-numbers,llvm-include-order" \
		-fix '{}'

dump-format-config:
	@clang-format --fcolor-diagnostics --Werror --verbose --style=file --dump-config

clean:
	@rm -f fs/userland.elf
	@rm -rf zig-cache
	@rm -rf bin
