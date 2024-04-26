const zasm = @import("zasm.zig");

// -----------------------------------------------------------------------------
// null (guard):         0000000000000000 - 0000000000200000 (1 page, 2 MB)
//
// unmapped boot:        0000000000100000 - 0000000?????????
//
// page tables (guard):  000000000FE00000 - 0000000010000000 (1 page, 2 MB)
// page tables:          0000000010000000 - 0000000020000000 (128 page, 256 MB)
// page tables (guard):  0000000020000000 - 0000000020200000 (1 page, 2 MB)
//
// kernel code (guard):  000000000FE00000 - 0000000010000000 (1 page, 2 MB)
// kernel code:          0000000010000000 - 0000000020000000 (128 page, 256 MB)
// kernel code (guard):  0000000020000000 - 0000000020200000 (1 page, 2 MB)
//
// kernel data (guard):  000000002FE00000 - 0000000030000000 (1 pages, 2 MB)
// kernel data:          0000000030000000 - 0000000040000000 (128 pages, 256 MB)
// kernel data (guard):  0000000040000000 - 0000000040200000 (1 pages, 2 MB)
//
// kernel stack (guard): 000000004FE00000 - 0000000050000000 (1 page, 2 MB)
// kernel stack:         0000000050000000 - 0000000060000000 (128 pages, 256 MB)
// kernel stack (guard): 0000000060000000 - 0000000060200000 (1 page, 2 MB)
//
// userland (guard):     0x0000009FE00000 - 00000000A0000000 (1 page, 2 MB)
// userland              00000000A0000000 - 00000000E0000000 (512 pages, 1GB)
// userland (guard):     00000000E0000000 - 00000000E0200000 (1 page, 2 MB)
//
// frame buffer:         00000000FD000000 - 00000000FD600000 (3 pages, 6 MB)
// -----------------------------------------------------------------------------

pub const NUM_NULL_PAGES = 0;
pub const NUM_MULTIMUPP_PAGES = 5;
pub const NUM_KERNEL_CODE_PAGES = 128 + 1 + 1; // 2 guard pages.
pub const NUM_KERNEL_DATA_PAGES = 128 + 1 + 1; // 2 guard pages.
pub const NUM_KERNEL_STACK_PAGES = 128 + 1 + 1; // 2 guard pages.
pub const NUM_USERLAND_PAGES = 64 + 1 + 1; // 2 guard pages.
// 4 bytes per pixel, 1280x1024 pixels = 5 MiB => three (3) pages of 2MiB.
pub const NUM_FRAME_BUFFER_PAGES = 3;

pub const P2_NULL_ADDR = 0x0;
pub const P2_MULTIMUPP_ADDR = 0x000000;
pub const P2_KERNEL_CODE_ADDR = 0x000000010000000;
export const P2_KERNEL_DATA_ADDR_EXPORT: u64 = 0x000000030000000;
pub const P2_KERNEL_DATA_ADDR = P2_KERNEL_DATA_ADDR_EXPORT;
pub const P2_KERNEL_STACK_ADDR = 0x000000050000000;
export const P2_USERLAND_ADDR_EXPORT: u64 = 0x0000000a0000000;
pub const P2_USERLAND_ADDR = P2_USERLAND_ADDR_EXPORT;

// TODO: don't hard-code frame buffer address..
pub const P2_FRAME_BUFFER_ADDR = 0x0000000FD000000;

pub const P2_NULL_FIRST_INDEX = 0; // [0, 1)
pub const P2_MULTIMUPP_FIRST_INDEX = P2_NULL_FIRST_INDEX + NUM_NULL_PAGES; // [0, 1)
pub const P2_KERNEL_CODE_FIRST_INDEX = P2_MULTIMUPP_FIRST_INDEX + NUM_MULTIMUPP_PAGES; // [1, 131)
pub const P2_KERNEL_DATA_FIRST_INDEX = P2_KERNEL_CODE_FIRST_INDEX + NUM_KERNEL_CODE_PAGES; // [131, 261)
pub const P2_KERNEL_STACK_FIRST_INDEX = P2_KERNEL_DATA_FIRST_INDEX + NUM_KERNEL_DATA_PAGES; // [261, 391)
pub const P2_USERLAND_FIRST_INDEX = P2_KERNEL_STACK_FIRST_INDEX + NUM_KERNEL_STACK_PAGES; // [391, 455)
pub const P2_FRAME_BUFFER_FIRST_INDEX = P2_USERLAND_FIRST_INDEX + NUM_USERLAND_PAGES; // [455, 458)

// Remember, skip the last guard page. // TODO: verify that we can update to not include last guard page.
export const KERNEL_STACK_TOP = P2_KERNEL_STACK_ADDR + page_size * (NUM_KERNEL_STACK_PAGES - 3);

pub const page_size = zasm.PageSize.Size2MiB.bytes(); // 2 * 1024 * 1024 = 0x200000
