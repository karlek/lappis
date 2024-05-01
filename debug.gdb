set disassembly-flavor intel

symbol-file bin/kernel.dbg

source ../gef/gef.py
source ../gdb-pt-dump/pt.py

gef-remote --qemu-user localhost 1234
# Any break points should be set here.
# break main
break enter_userland
break *(enter_userland+65)
break yay_userland

# Run until the program first breakpoint.
continue
