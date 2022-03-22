const c = @cImport({
    @cInclude("serial.h");
});

export fn foo(
    asdf: usize,
) callconv(.C) usize {
    const buf = "Zig zag zaggazoo\n";
    c.debug_buffer(@ptrCast([*]const u8, buf), buf.len);

    return asdf + 1337;
}
