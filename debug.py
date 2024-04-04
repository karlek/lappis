import gdb
from curses.ascii import isgraph

def groups_of(iterable, size, first=0):
    first = first if first != 0 else size
    chunk, iterable = iterable[:first], iterable[first:]
    while chunk:
        yield chunk
        chunk, iterable = iterable[:size], iterable[size:]

class HexDump(gdb.Command):
    def __init__(self):
        super (HexDump, self).__init__ ('hd', gdb.COMMAND_DATA)

    def invoke(self, arg, from_tty):
        argv = gdb.string_to_argv(arg)

        addr = gdb.parse_and_eval(argv[0]).cast(
            gdb.lookup_type('void').pointer())
        if len(argv) == 2:
             try:
                 bytes = int(gdb.parse_and_eval(argv[1]))
             except ValueError:
                 raise gdb.GdbError('Byte count numst be an integer value.')
        else:
             bytes = 500

        inferior = gdb.selected_inferior()

        align = gdb.parameter('hex-dump-align')
        width = gdb.parameter('hex-dump-width')
        if width == 0:
            width = 16

        mem = inferior.read_memory(addr, bytes)
        pr_addr = int(str(addr), 16)
        pr_offset = width

        if align:
            pr_offset = width - (pr_addr % width)
            pr_addr -= pr_addr % width
        start=(pr_addr) & 0xff;


        print ('            ' , end="")
        print ('  '.join(['%01X' % (i&0x0f,) for i in range(start,start+width)]) , end="")
        print ('  ' , end="")
        print (' '.join(['%01X' % (i&0x0f,) for i in range(start,start+width)]) )

        for group in groups_of(mem, width, pr_offset):
            print ('0x%x: ' % (pr_addr,) + '   '*(width - pr_offset), end="")
            print (' '.join(['%02X' % (ord(g),) for g in group]) + \
                '   ' * (width - len(group) if pr_offset == width else 0) + ' ', end="")
            print (' '*(width - pr_offset) +  ' '.join(
                [chr( int.from_bytes(g, byteorder='big')) if isgraph( int.from_bytes(g, byteorder='big')   ) or g == ' ' else '.' for g in group]))
            pr_addr += width
            pr_offset = width

class HexDumpAlign(gdb.Parameter):
    def __init__(self):
        super (HexDumpAlign, self).__init__('hex-dump-align',
                                            gdb.COMMAND_DATA,
                                            gdb.PARAM_BOOLEAN)

    set_doc = 'Determines if hex-dump always starts at an "aligned" address (see hex-dump-width'
    show_doc = 'Hex dump alignment is currently'

class HexDumpWidth(gdb.Parameter):
    def __init__(self):
        super (HexDumpWidth, self).__init__('hex-dump-width',
                                            gdb.COMMAND_DATA,
                                            gdb.PARAM_INTEGER)

    set_doc = 'Set the number of bytes per line of hex-dump'

    show_doc = 'The number of bytes per line in hex-dump is'

HexDump()
HexDumpAlign()
HexDumpWidth()

import gdb

class StepBeforeNextCall (gdb.Command):
    def __init__ (self):
        super (StepBeforeNextCall, self).__init__ ("step-before-next-call",
                                                   gdb.COMMAND_OBSCURE)

    def invoke (self, arg, from_tty):
        arch = gdb.selected_frame().architecture()

        while True:
            current_pc = addr2num(gdb.selected_frame().read_register("pc"))
            disa = arch.disassemble(current_pc)[0]
            if "call" in disa["asm"]: # or startswith ?
                break

            SILENT=True
            gdb.execute("stepi", to_string=SILENT)

        print("step-before-next-call: next instruction is a call.")
        print("{}: {}".format(hex(int(disa["addr"])), disa["asm"]))

def addr2num(addr):
    try:
        return int(addr)  # Python 3
    except:
        return long(addr) # Python 2

StepBeforeNextCall()


import gdb

def callstack_depth():
    depth = 1
    frame = gdb.newest_frame()
    while frame is not None:
        frame = frame.older()
        depth += 1
    return depth

class StepToNextCall (gdb.Command):
    def __init__ (self):
        super (StepToNextCall, self).__init__ ("step-to-next-call",
                                               gdb.COMMAND_OBSCURE)

    def invoke (self, arg, from_tty):
        start_depth = current_depth =callstack_depth()

        # step until we're one step deeper
        while current_depth == start_depth:
            SILENT=True
            gdb.execute("step", to_string=SILENT)
            current_depth = callstack_depth()

        # display information about the new frame
        gdb.execute("frame 0")

StepToNextCall()
