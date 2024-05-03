set disassembly-flavor intel

symbol-file bin/kernel.dbg

source ../gef/gef.py
source ../gdb-pt-dump/pt.py

gef-remote --qemu-user localhost 1234

# Any break points should be set here.
break enter_userland
commands
	# TODO: hard-coded userland entrypoint. But _sooo_ good for debugging.
	add-symbol-file bin/userland.elf 0xa0300000+0x30
	break elf_userland
	continue
end
break syscall_landing_pad

# Run until the program first breakpoint.
continue
