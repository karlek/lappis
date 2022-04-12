
# jump in

## todo

- [ ] Syntax for driver kaitai
- [ ] Write your own kaitai
- [ ] Update log entries & add recent images.
- [ ] Solve testing
- [ ] Understand and improve `linker.ld` (such a weird syntax)
      Reference: https://github.com/stevej/osdev/blob/master/kernel/link.ld
- [ ] Actually detect Long mode with cpuid
	- [ ] Actually detect if we can enable FPU (although isn't this assumed with
		  long mode? :thinking:)
- [ ] Writable filesystem
	- Use an actual filesystem
- [ ] Dockerfile
- [ ] Fast ATA reading.
- [ ] inline masm intel syntax in clang

## paging in c

- [ ] Map RSDT address
	[ ] DSDT
	[ ] RSDP -> RSDT
- [ ] Auto update video & heap start/end when editing paging
- [ ] Null pointer trap page
- [ ] Separate interrupt table and kernel code, i.e. not same page. 
	- [ ] IDT needs to be writable, make a primitive to toggle writability of a
		  page before adding a new idt.
- [ ] `NUM_PAGES` is stupid
- [ ] Rewrite the paging into C

## soon

- [ ] Actually write a memory allocator that frees
- [ ] Make a shell!
	- [ ] Kernel printing with scrolling/redrawing you name it.
	- [ ] Compositor needed?
- [ ] Fiverr a logo
	- [ ] How the fuck do I pay?
- [ ] Update README.md
- [ ] Add sound
- [ ] UEFI
- [ ] Simulate network over serial / FIFO pipe / nc
- [ ] Add IPv4
- [ ] Add ICMP
- [ ] Add UDP
- [ ] Add ethernet
- [ ] Userland

## later (if ever)

- [ ] la57 (five level paging, cr4 bit 12)
- [ ] nasm linting
- [ ] Auto-format nasm code
- [ ] https://gist.github.com/Aerijo/df27228d70c633e088b0591b8857eeef
      https://tree-sitter.github.io/tree-sitter/creating-parsers

## done

- [x] c linting
- [x] clang-tidy `readability-braces-around-statements`
- [x] Test clang instead of gcc
- [x] Try making a rust <> call
- [x] Try making a zig  <> call
- [x] `sleep`
- [x] ide poll error?
	  https://wiki.osdev.org/IDE
- [x] multiboot?
- [x] memcpy single file?
- [x] debug __FILE__:__LINE__
- [x] debug printf
- [x] No more RWX kernel heap
- [x] Do we even respect the NX?
- [x] No more RWX stack
- [x] Remove the need for a wrapped zipfs
- [x] Make kernel stack guard paged for sanity.
- [x] Extract paging code from `long_mode.asm` into `paging.asm` or `paging.c`
- [x] Add Github Action for `make compile`
- [x] Auto-format c code
