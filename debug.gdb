target remote localhost:1234
symbol-file bin/kernel.dbg

break kernel/format/zip.c:68
# Run until the program first breakpoint.
continue

break *(memcpy+33)
commands
telescope $rsp-0x50 12
end

break *(memcpy+41)
commands
telescope $rsp-0x50 12
end

break *(memcpy+55)
commands
telescope $rsp-0x50 12
end

break *(memcpy+73)
commands
telescope $rsp-0x50 12
end
