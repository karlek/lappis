const zasm = @import("zasm.zig");

// kernel code          0000000000000000 - 0000000000200000 --PDA--UW
// kernel data          0000000000200000 - 0000000004000000 --PDA--UW
// kernel stack (guard) 0000000004000000 - 0000000004200000 X-P------
// kernel stack         0000000004200000 - 0000000004400000 X-PDA---W
// kernel stack (guard) 0000000004600000 - 0000000004800000 X-P------
// frame buffer         00000000fd000000 - 00000000fd600000 X-PDA---W

// -----------------------------------------------------------------------------
// kernel code:          0000000000000000 - 0000000000200000 (1 page, 2 MB)
// kernel data:          0000000000200000 - 0000000004000000 (31 pages, 62 MB)
// kernel stack (guard): 0000000004000000 - 0000000004200000 (1 page, 2 MB)
// kernel stack:         0000000004200000 - 0000000004600000 (2 pages, 4 MB)
// kernel stack (guard): 0000000004600000 - 0000000004800000 (1 page, 2 MB)
//
// frame buffer:         00000000FD000000 - 00000000FD600000 (3 pages, 6 MB)
// -----------------------------------------------------------------------------

// NUM_KERNEL_CODE_PAGES + NUM_KERNEL_DATA_PAGES = 32 (NUM_PAGES)
pub const NUM_KERNEL_CODE_PAGES = 1;
pub const NUM_KERNEL_DATA_PAGES = 31;
// 1 guard page, NUM_KERNEL_STACK_PAGES-2 stack pages, 1 guard page
pub const NUM_KERNEL_STACK_PAGES = 4;
pub const NUM_USERLAND_PAGES = 128; // should be enough for everyone
// 4 bytes per pixel, 1280x1024 pixels = 5 MiB => three (3) pages of 2MiB.
pub const NUM_FRAME_BUFFER_PAGES = 3;

pub const P2_KERNEL_CODE_FIRST_INDEX = 0; // [0, 1)
pub const P2_KERNEL_DATA_FIRST_INDEX = P2_KERNEL_CODE_FIRST_INDEX + NUM_KERNEL_CODE_PAGES; // [1, 32)
pub const P2_KERNEL_STACK_FIRST_INDEX = P2_KERNEL_DATA_FIRST_INDEX + NUM_KERNEL_DATA_PAGES; // [32, 36)
pub const P2_USERLAND_FIRST_INDEX = P2_KERNEL_STACK_FIRST_INDEX + NUM_KERNEL_STACK_PAGES; // [32, 36)
pub const P2_FRAME_BUFFER_FIRST_INDEX = P2_USERLAND_FIRST_INDEX + NUM_USERLAND_PAGES; // [36, 39)

// Remember, skip the last guard page.
pub const STACK_TOP = page_size * (P2_KERNEL_STACK_FIRST_INDEX + (NUM_KERNEL_STACK_PAGES - 1));
export const KERNEL_DATA_ADDR: c_long = page_size * P2_KERNEL_DATA_FIRST_INDEX;
export const KERNEL_DATA_END_ADDR: c_long = page_size * (P2_KERNEL_DATA_FIRST_INDEX + NUM_KERNEL_DATA_PAGES);
export const USERLAND_ADDR: c_long = page_size * P2_USERLAND_FIRST_INDEX;
export const USERLAND_END_ADDR: c_long = page_size * (P2_USERLAND_FIRST_INDEX + NUM_USERLAND_PAGES);
export const FRAME_BUFFER_ADDR: c_long = page_size * P2_FRAME_BUFFER_FIRST_INDEX;

pub const page_size = zasm.PageSize.Size2MiB.bytes(); // 2 * 1024 * 1024 = 0x200000
