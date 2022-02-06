
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

# X86

## Double fault everywhere, `jmp $`, double for-loop, etc.

Solution: Remove call to `sti`, since you probably haven't added complete
support for hardware interrupts.

"Apparently in x86, you have to acknowledge clock interrupts after each one. I.e
one must send an acknowledgment to the lapic after every clock interrupt."
