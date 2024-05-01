const zasm = @import("zasm.zig");

// bootstrap            0000000000000000 - 0000000000200000 --PDA---W // (1 page)
// bootstrap (guard)    0000000000200000 - 0000000000400000 X-P------ // (1 page)
//
// kernel code (guard)  000000000fe00000 - 0000000010000000 --PDA---- // (1 page)
// kernel code          0000000010000000 - 0000000010200000 --PDA---W // (1 page) TODO: RWX..
// kernel code (guard)  0000000010200000 - 0000000010400000 --PDA---- // (1 page)
//
// kernel data (guard)  000000002fe00000 - 0000000030000000 X-PDA---- // (1 page)
// kernel data          0000000030000000 - 0000000033e00000 X-PDA---W // (31 pages)
// kernel data (guard)  0000000033e00000 - 0000000034000000 X-PDA---- // (1 page)
//
// kernel stack (guard) 000000004fe00000 - 0000000050000000 X-P------ // (1 page)
// kernel stack         0000000050000000 - 0000000050800000 X-PDA---W // (4 pages)
// kernel stack (guard) 0000000050800000 - 0000000050a00000 X-P------ // (1 page)
//
// userland (guard)     000000009fe00000 - 00000000a0000000 X-P------ // (1 page)
// userland             00000000a0000000 - 00000000b0000000 --P----UW // (128 pages)
// userland (guard)     00000000b0000000 - 00000000b0200000 X-P------ // (1 page)
//
// frame buffer (guard) 00000000fd000000 - 00000000fd600000 X-PDA---- // (1 page)
// frame buffer         00000000fd000000 - 00000000fd600000 X-PDA---W // (3 pages)
// frame buffer (guard) 00000000fd000000 - 00000000fd600000 X-PDA---- // (1 page)
//
// ---------------------------------------------------------------------------------
//
// gef> pt -p
//           Address :         Length :         Phys | Permissions
//               0x0 :       0x200000 :          0x0 | W:1 X:1 S:1 UC:0 WB:1
//          0x200000 :       0x200000 :     0x200000 | W:0 X:0 S:1 UC:0 WB:1
//         0xfe00000 :       0x200000 :    0xfe00000 | W:0 X:0 S:1 UC:0 WB:1
//        0x10000000 :       0x200000 :   0x10000000 | W:1 X:1 S:1 UC:0 WB:1
//        0x10200000 :       0x200000 :   0x10200000 | W:0 X:0 S:1 UC:0 WB:1
//        0x2fe00000 :       0x200000 :   0x2fe00000 | W:0 X:0 S:1 UC:0 WB:1
//        0x30000000 :      0x3e00000 :   0x30000000 | W:1 X:0 S:1 UC:0 WB:1
//        0x33e00000 :       0x200000 :   0x33e00000 | W:0 X:0 S:1 UC:0 WB:1
//        0x4fe00000 :       0x200000 :   0x4fe00000 | W:0 X:0 S:1 UC:0 WB:1
//        0x50000000 :       0x800000 :   0x50000000 | W:1 X:0 S:1 UC:0 WB:1
//        0x50800000 :       0x200000 :   0x50800000 | W:0 X:0 S:1 UC:0 WB:1
//        0x9fe00000 :       0x200000 :   0x9fe00000 | W:0 X:0 S:1 UC:0 WB:1
//        0xa0000000 :     0x10000000 :   0xa0000000 | W:1 X:1 S:0 UC:0 WB:1
//        0xb0000000 :       0x200000 :   0xb0000000 | W:0 X:0 S:1 UC:0 WB:1
//        0xfce00000 :       0x200000 :   0xfce00000 | W:0 X:0 S:1 UC:0 WB:1
//        0xfd000000 :       0x600000 :   0xfd000000 | W:1 X:0 S:1 UC:0 WB:1
//        0xfd600000 :       0x200000 :   0xfd600000 | W:0 X:0 S:1 UC:0 WB:1

pub const NUM_BOOTSTRAP_PAGES = 2;
pub const NUM_KERNEL_CODE_PAGES = 1;
pub const NUM_KERNEL_DATA_PAGES = 31;
pub const NUM_KERNEL_STACK_PAGES = 4;
pub const NUM_USERLAND_PAGES = 128; // should be enough for everyone
pub const NUM_FRAME_BUFFER_PAGES = 3; // 4 bytes per pixel, 1280x1024 pixels = 5 MiB => three (3) pages of 2MiB.

// Remember, skip the last guard page.
export const STACK_TOP = page_size * (P2_KERNEL_STACK_FIRST_INDEX + (NUM_KERNEL_STACK_PAGES - 1));

export const KERNEL_DATA_ADDR: c_long = page_size * P2_KERNEL_DATA_FIRST_INDEX;
export const KERNEL_DATA_END_ADDR: c_long = page_size * (P2_KERNEL_DATA_FIRST_INDEX + NUM_KERNEL_DATA_PAGES);
export const USERLAND_ADDR: u64 = page_size * P2_USERLAND_FIRST_INDEX;
export const USERLAND_END_ADDR: u64 = page_size * (P2_USERLAND_FIRST_INDEX + NUM_USERLAND_PAGES);
export const FRAME_BUFFER_ADDR: u64 = page_size * P2_FRAME_BUFFER_FIRST_INDEX;

pub const P2_BOOTSTRAP_FIRST_INDEX = 0;
pub const P2_BOOTSTRAP_END_GUARD_INDEX = P2_BOOTSTRAP_FIRST_INDEX + NUM_BOOTSTRAP_PAGES;

pub const P2_KERNEL_CODE_START_GUARD_INDEX = P2_KERNEL_CODE_FIRST_INDEX - 1;
pub const P2_KERNEL_CODE_FIRST_INDEX = 128; // 0x10000000 / 0x200000 (page_size) = 128
pub const P2_KERNEL_CODE_END_GUARD_INDEX = P2_KERNEL_CODE_FIRST_INDEX + NUM_KERNEL_CODE_PAGES;

pub const P2_KERNEL_DATA_START_GUARD_INDEX = P2_KERNEL_DATA_FIRST_INDEX - 1;
pub const P2_KERNEL_DATA_FIRST_INDEX = 384; // 0x30000000 / 0x200000 (page_size) = 384
pub const P2_KERNEL_DATA_END_GUARD_INDEX = P2_KERNEL_DATA_FIRST_INDEX + NUM_KERNEL_DATA_PAGES;

pub const P2_KERNEL_STACK_START_GUARD_INDEX = P2_KERNEL_STACK_FIRST_INDEX - 1;
pub const P2_KERNEL_STACK_FIRST_INDEX = 640; // 0x50000000 / 0x200000 (page_size) = 640
pub const P2_KERNEL_STACK_END_GUARD_INDEX = P2_KERNEL_STACK_FIRST_INDEX + NUM_KERNEL_STACK_PAGES;

pub const P2_USERLAND_START_GUARD_INDEX = P2_USERLAND_FIRST_INDEX - 1;
pub const P2_USERLAND_FIRST_INDEX = 1280; // 0xa0000000 / 0x200000 (page_size) = 1280
pub const P2_USERLAND_END_GUARD_INDEX = P2_USERLAND_FIRST_INDEX + NUM_USERLAND_PAGES;

pub const P2_FRAME_BUFFER_START_GUARD_INDEX = P2_FRAME_BUFFER_FIRST_INDEX - 1;
pub const P2_FRAME_BUFFER_FIRST_INDEX = 2024; // 0xfd000000 / 0x200000 (page_size) = 1280
pub const P2_FRAME_BUFFER_END_GUARD_INDEX = P2_FRAME_BUFFER_FIRST_INDEX + NUM_FRAME_BUFFER_PAGES;

pub const page_size = zasm.PageSize.Size2MiB.bytes(); // 2 * 1024 * 1024 = 0x200000

// tss64:
// 	           dd 0 ; Reserved
// 	.rsp0      dq STACK_TOP
// 	.rsp1      dq 0
// 	.rsp2      dq 0
// 	           dq 0 ; Reserved
// 	.ist1      dq 0
// 	.ist2      dq 0
// 	.ist3      dq 0
// 	.ist4      dq 0
// 	.ist5      dq 0
// 	.ist6      dq 0
// 	.ist7      dq 0
// 	           dq 0 ; Reserved
// 	           dw 0 ; Reserved
// 	.iopb      dw 0 ; no IOPB

const Tss64 = packed struct {
    reserved1: u32,
    rsp0: u64,
    rsp1: u64,
    rsp2: u64,
    reserved2: u64,
    ist1: u64,
    ist2: u64,
    ist3: u64,
    ist4: u64,
    ist5: u64,
    ist6: u64,
    ist7: u64,
    reserved3: u64,
    reserved4: u64,
    iopb: u64,

    /// Creates an unused page table entry.
    pub fn init(stack: u64) Tss64 {
        return .{
            .reserved1 = 0,
            .rsp0 = stack,
            .rsp1 = 0,
            .rsp2 = 0,
            .reserved2 = 0,
            .ist1 = 0,
            .ist2 = 0,
            .ist3 = 0,
            .ist4 = 0,
            .ist5 = 0,
            .ist6 = 0,
            .ist7 = 0,
            .reserved3 = 0,
            .reserved4 = 0,
            .iopb = 0,
        };
    }
};

export var tss64_addr: u64 = 0;

export fn init_tss_addr() void {
    const tss64: Tss64 = Tss64.init(STACK_TOP);
    tss64_addr = @intFromPtr(&tss64);
}
