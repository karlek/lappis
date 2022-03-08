target remote localhost:1234
symbol-file bin/kernel.dbg

break kernel/format/zip.c:63
# Run until the program first breakpoint.
continue
# Add break points that will be added after our first breakpoint has been hit.
