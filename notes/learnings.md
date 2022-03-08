
# QEMU

## In `info registers`: Why aren't my registers 64 bit?

QEMU prints the CPU state in the 32 bit format if the CPU is
currently in 32-bit mode, and in 64 bit format if it is currently
in 64-bit mode. So it simply depends what the CPU happens to be
doing at any given time.

## I'm stuck

`Ctrl-Alt-2` > `quit`

## VGA mode does not display anything? i.e. `mov [0xb8000], 0x0f680f69`

Are you sure you're not running qemu in `-nographics`? Test `-curses`

## How do I dump RAM to file?

`Ctrl-Alt-2` > `dump-guest-memory /tmp/mem`

# X86

## Double fault everywhere, `jmp $`, double for-loop, etc.

Solution: Remove call to `sti`, since you probably haven't added complete
support for hardware interrupts.

"Apparently in x86, you have to acknowledge clock interrupts after each one. I.e
one must send an acknowledgment to the lapic after every clock interrupt."

# GCC

## Red Zones

The 128-byte area beyond the location pointed to by %rsp is considered
to be reserved and shall not be modified by signal or interrupt
handlers. Therefore, functions may use this area for temporary data that
is not needed across function calls. In particular, leaf functions may
use this area for their entire stack frame, rather than adjusting the
stack pointer in the prologue and epilogue. This area is known as the
red zone.

This combined with a timer, that's non-deterministic can create headaches.
Especially since the more you debug, the longer it takes to happen. If you would
have a watch expression like: `watch $rax >= 0x100000`, the bug would not
happpen. The stack would be corrupted between loop iterations, and read from a
non-mapped memory, giving not a page fault, but a general protection fault
instead. Since the memory page mapping descriptor describing that virtual
address is zeroed out. The error code is zero since it's not segment related.
Fun times.
