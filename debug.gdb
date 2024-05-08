set disassembly-flavor intel

symbol-file bin/kernel.dbg

source ../gef/gef.py
source ../gdb-pt-dump/pt.py

gef-remote --qemu-user localhost 1234

# Any break points should be set here.
break enter_userland
commands
	# NOTE: breakpoints on userland functions should be defined here!

	# TODO: hard-coded userland entrypoint. But _sooo_ good for debugging.
	add-symbol-file bin/userland.elf 0xa0300000+0x30

	# break elf_userland
	# Good tool when you want to relinquish control back to GDB from source.
	break debug_interrupt

	continue
end

# Run until the program first breakpoint.
continue

# Handy way to debug the userland callstack.
# hexdump byte 0xa0200ff0 --size 0x100 --reverse
