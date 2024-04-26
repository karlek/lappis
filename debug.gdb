set disassembly-flavor intel

# source debug.py
# source /usr/share/pwndbg/gdbinit.py
source /usr/share/gef/gef.py

target remote localhost:1234
symbol-file bin/kernel.dbg

# Any break points should be set here.
# break main
break init_long_mode
# break enable_paging
break enter_userland
break *(enter_userland+65)
break yay_userland

# Run until the program first breakpoint.
continue

# Add break points that will be added after our first breakpoint has been hit.
# break irq_timer
# break *irq_timer+24
# break not_implemented_0
