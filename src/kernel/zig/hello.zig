const c = @cImport({
    @cInclude("/home/_/src/karlek/lapis/src/kernel/serial.h");
});

// comptime {
//     @export(hello, .{ .name = "foo", .linkage = .Strong });
// }

export fn foo(
    asdf: usize,
) callconv(.C) usize {
    const buf = "Zig zag zaggazoo";
    c.debug_buffer(@ptrCast([*]const u8, buf), buf.len);

    return asdf + 1337;
}
