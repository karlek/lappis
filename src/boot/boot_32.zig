const std = @import("std");

const multiboot2 = @cImport(@cInclude("multiboot2.h"));

const MultiMupp = extern struct {
    hdr: multiboot2.multiboot_header,

    // NOTE: multiboot tags must be 8 byte aligned.
    frame_buffer_tag: multiboot2.multiboot_header_tag_framebuffer,
    padding: [4]u8, // TODO: replace with align(8)
    end_tag: multiboot2.multiboot_header_tag,
};

const MAGIC = @as(u32, multiboot2.MULTIBOOT2_HEADER_MAGIC);
const ARCH = @as(u32, multiboot2.MULTIBOOT2_ARCHITECTURE_I386);
const LENGTH = @as(u32, @sizeOf(MultiMupp));

export var multiboot linksection(".multiboot") = MultiMupp{
    .hdr = .{
        .magic = MAGIC,
        .architecture = ARCH,
        .header_length = LENGTH,
        .checksum = @as(u32, @bitCast(-@as(i32, @bitCast(MAGIC + ARCH + LENGTH)))), // gotta love bitcasts.
    },
    .frame_buffer_tag = .{
        .type = multiboot2.MULTIBOOT_HEADER_TAG_FRAMEBUFFER,
        .flags = multiboot2.MULTIBOOT_FRAMEBUFFER_TYPE_RGB,
        .size = @sizeOf(multiboot2.multiboot_header_tag_framebuffer),
        .width = 1280,
        .height = 1024,
        .depth = 32,
    },
    .padding = [4]u8{ 0, 0, 0, 0 }, // TODO: use align 8 instead.
    .end_tag = .{
        .type = multiboot2.MULTIBOOT_HEADER_TAG_END,
        .flags = 0,
        .size = @sizeOf(multiboot2.multiboot_header_tag),
    },
};

extern fn init_long_mode() void;

export fn multiboot_start() callconv(.Naked) noreturn {
    //init_long_mode(); // TODO: call from Zig instead of inline asm when supported in Zig.

    asm volatile (
        \\ call init_long_mode
    );

    while (true) {}
}
