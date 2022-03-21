const std = @import("std");
const builtin = @import("builtin");
const print = @import("std").debug.print;
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.build.Builder) void {
    // TODO: `zig-cache/` still gets created in project root..?
    b.cache_root = "./bin/zig-cache";
    b.build_root = "./bin";

    const obj = b.addObject("libhello", "src/kernel/zig/hello.zig");
    const target = CrossTarget{
        .cpu_arch = std.Target.Cpu.Arch.x86_64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.gnu,
    };
    obj.setTarget(target);

    obj.setBuildMode(.Debug);

    // Disable red zone.
    obj.red_zone = false;

    obj.addIncludeDir("src/kernel");
    obj.setOutputDir("bin");

    b.default_step.dependOn(&obj.step);
}
