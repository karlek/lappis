const std = @import("std");
const zasm = @import("zasm.zig");
const paging = @import("paging.zig");

const P2_MAX_ENTRIES = 512;
export var p4_table: [512]u64 align(4096) = std.mem.zeroes([512]u64); // [4096]u8
export var p3_table: [512]u64 align(4096) = std.mem.zeroes([512]u64); // [4096]u8
export var p2_tables: [4][P2_MAX_ENTRIES]u64 align(4096) = std.mem.zeroes([4][P2_MAX_ENTRIES]u64); // [4][4096]u8

export fn set_up_page_tables() void {
    // Map the first P4 entry to P3 table.
    var p4_page_table_entry = zasm.PageTableEntry.init();
    // Set flags `present`, `writeable` and `user accessible`.
    var p4_page_table_flags = p4_page_table_entry.getFlags();
    p4_page_table_flags.present = true;
    p4_page_table_flags.writeable = true;
    p4_page_table_flags.user_accessible = true;
    p4_page_table_entry.setFlags(p4_page_table_flags);
    // Set address of page table entry.
    const raw_p3_addr = @as(u64, @intCast(@intFromPtr(&p3_table[0])));
    const p3_addr = zasm.PhysAddr.initUnchecked(raw_p3_addr);
    p4_page_table_entry.setAddr(p3_addr);
    // Set page table entry.
    p4_table[0] = p4_page_table_entry.entry;

    // Map the first P3 entry to P2 table.
    var p3_page_table_entry = zasm.PageTableEntry.init();
    // Set flags `present`, `writeable` and `user accessible`.
    var p3_page_table_flags = p3_page_table_entry.getFlags();
    p3_page_table_flags.present = true;
    p3_page_table_flags.writeable = true;
    p3_page_table_flags.user_accessible = true;
    p3_page_table_entry.setFlags(p3_page_table_flags);

    var i: usize = 0;
    while (i < 4) : (i += 1) {
        p2_tables[i] = std.mem.zeroes([P2_MAX_ENTRIES]u64);
        // Set address of page table entry.
        const raw_p2_addr = @as(u64, @intCast(@intFromPtr(&p2_tables[i])));
        const p2_addr = zasm.PhysAddr.initUnchecked(raw_p2_addr);
        p3_page_table_entry.setAddr(p2_addr);
        // Set page table entry.
        p3_table[i] = p3_page_table_entry.entry;
    }
}

export fn map_bootstrap() void {
    var page_table_flags = zasm.PageTableFlags.fromU64(0);
    // NOTE: `no execute` is _not_ set.
    page_table_flags.present = true;
    page_table_flags.writeable = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).

    const p2_index_offset = paging.P2_BOOTSTRAP_FIRST_INDEX; // page index offset into P2 table of userland pages.
    const kernel_code_base_addr = p2_index_offset * paging.page_size;
    map(kernel_code_base_addr, paging.P2_BOOTSTRAP_FIRST_INDEX, paging.NUM_KERNEL_CODE_PAGES, page_table_flags);

    // Guard page.
    const guard_index = paging.P2_BOOTSTRAP_END_GUARD_INDEX;
    map_guard(guard_index);
}

export fn map_kernel_code_segment() void {
    var page_table_flags = zasm.PageTableFlags.fromU64(0);
    // NOTE: `no execute` is _not_ set.
    page_table_flags.present = true;
    page_table_flags.writeable = true; // TODO: unset writeable and set no_execute for kernel code segment?
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).

    // Guard page.
    var guard_index: usize = paging.P2_KERNEL_CODE_START_GUARD_INDEX;
    map_guard(guard_index);

    const p2_index_offset = paging.P2_KERNEL_CODE_FIRST_INDEX; // page index offset into P2 table of userland pages.
    const kernel_code_base_addr = p2_index_offset * paging.page_size;
    map(kernel_code_base_addr, paging.P2_KERNEL_CODE_FIRST_INDEX, paging.NUM_KERNEL_CODE_PAGES, page_table_flags);

    // Guard page.
    guard_index = paging.P2_KERNEL_CODE_END_GUARD_INDEX;
    map_guard(guard_index);
}

export fn map_kernel_data_segment() void {
    var page_table_flags = zasm.PageTableFlags.fromU64(0);
    page_table_flags.present = true;
    page_table_flags.writeable = true;
    page_table_flags.no_execute = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).

    // Guard page.
    var guard_index: usize = paging.P2_KERNEL_DATA_START_GUARD_INDEX;
    map_guard(guard_index);

    const p2_index_offset = paging.P2_KERNEL_DATA_FIRST_INDEX; // page index offset into P2 table of userland pages.
    const kernel_data_base_addr = p2_index_offset * paging.page_size;
    map(kernel_data_base_addr, paging.P2_KERNEL_DATA_FIRST_INDEX, paging.NUM_KERNEL_DATA_PAGES, page_table_flags);

    // Guard page.
    guard_index = paging.P2_KERNEL_DATA_END_GUARD_INDEX;
    map_guard(guard_index);
}

export fn map_kernel_stack() void {
    var page_table_flags = zasm.PageTableFlags.fromU64(0);
    page_table_flags.present = true;
    page_table_flags.writeable = true;
    page_table_flags.no_execute = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).

    // Guard page.
    var guard_index: usize = paging.P2_KERNEL_STACK_START_GUARD_INDEX;
    map_guard(guard_index);

    const p2_index_offset = paging.P2_KERNEL_STACK_FIRST_INDEX; // page index offset into P2 table of userland pages.
    const kernel_stack_base_addr = p2_index_offset * paging.page_size;
    map(kernel_stack_base_addr, paging.P2_KERNEL_STACK_FIRST_INDEX, paging.NUM_KERNEL_STACK_PAGES, page_table_flags);

    // Guard page.
    guard_index = paging.P2_KERNEL_STACK_END_GUARD_INDEX;
    map_guard(guard_index);
}

export fn map_userland() void {
    var page_table_flags = zasm.PageTableFlags.fromU64(0);
    page_table_flags.present = true;
    page_table_flags.writeable = true;
    page_table_flags.user_accessible = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).

    // Guard page.
    var guard_index: usize = paging.P2_USERLAND_START_GUARD_INDEX;
    map_guard(guard_index);

    const p2_index_offset = paging.P2_USERLAND_FIRST_INDEX; // page index offset into P2 table of userland pages.
    const userland_base_addr = p2_index_offset * paging.page_size;
    map(userland_base_addr, paging.P2_USERLAND_FIRST_INDEX, paging.NUM_USERLAND_PAGES, page_table_flags);

    // Guard page.
    guard_index = paging.P2_USERLAND_END_GUARD_INDEX;
    map_guard(guard_index);
}

export fn map_frame_buffer() void {
    // TODO: hard-coded
    const frame_buffer_base_addr = 0xFD000000;

    var page_table_flags = zasm.PageTableFlags.fromU64(0);
    page_table_flags.present = true;
    page_table_flags.writeable = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).
    page_table_flags.no_execute = true;

    // Guard page.
    var guard_index: usize = paging.P2_FRAME_BUFFER_START_GUARD_INDEX;
    map_guard(guard_index);

    map(frame_buffer_base_addr, paging.P2_FRAME_BUFFER_FIRST_INDEX, paging.NUM_FRAME_BUFFER_PAGES, page_table_flags);

    // Guard page.
    guard_index = paging.P2_FRAME_BUFFER_END_GUARD_INDEX;
    map_guard(guard_index);
}

fn map(base_addr: u64, initial_offset: usize, num_pages: u64, page_table_flags: zasm.PageTableFlags) void {
    var page_table_entry = zasm.PageTableEntry.init();
    page_table_entry.setFlags(page_table_flags);

    const table_num = @divFloor(initial_offset, P2_MAX_ENTRIES);
    const p2_index_offset = initial_offset; // page index offset into P2 table of frame buffer pages.

    var page_num: usize = 0;
    while (page_num < num_pages) : (page_num += 1) {
        // Set address of page table entry.
        const page_offset = page_num * paging.page_size; // offset from start of frame buffer.
        const addr = zasm.PhysAddr.initUnchecked(base_addr + page_offset);
        page_table_entry.setAddr(addr);
        // Set page table entry.
        const p2_index = (page_num + p2_index_offset) % P2_MAX_ENTRIES;
        p2_tables[table_num][p2_index] = page_table_entry.entry;
    }
}

fn map_guard(offset: usize) void {
    var page_table_entry = zasm.PageTableEntry.init();
    var page_table_flags = zasm.PageTableFlags.fromU64(0);
    page_table_flags.present = true;
    page_table_flags.writeable = false;
    page_table_flags.no_execute = true;
    page_table_flags.user_accessible = false;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).
    page_table_entry.setFlags(page_table_flags);

    const base_addr = offset * paging.page_size;
    const addr = zasm.PhysAddr.initUnchecked(base_addr);
    page_table_entry.setAddr(addr);
    // Set page table entry.
    const p2_index = offset;
    const table_num = @divFloor(offset, P2_MAX_ENTRIES);
    p2_tables[table_num][p2_index % P2_MAX_ENTRIES] = page_table_entry.entry;
}

export fn enable_paging() void {
    // Enable PAE-flag in CR4 register. (Physical Address Extension).
    var cr4_value = zasm.Cr4.read();
    cr4_value.physical_address_extension = true; // 1 << 5
    cr4_value.write();

    // Set the long mode bit in the EFER MSR (Model Specific Register).
    var efer_value = zasm.Efer.read();
    efer_value.long_mode_enable = true; // 1 << 8
    // Set the NX bit.
    efer_value.no_execute_enable = true; // 1 << 11
    efer_value.write();

    // Load P4 to CR3 register. (CPU uses this to access the P4 table).
    const raw_p4_addr = @as(u64, @intCast(@intFromPtr(&p4_table[0])));
    const p4_addr = zasm.PhysAddr.initUnchecked(raw_p4_addr);
    const cr3_value = zasm.Cr3.Contents{
        .phys_frame = zasm.PhysFrame.fromStartAddressUnchecked(p4_addr),
        .cr3_flags = zasm.Cr3Flags.fromU64(0),
    };
    zasm.Cr3.write(cr3_value);

    // Enable paging in the CR0 register.
    var cr0_value = zasm.Cr0.read();
    cr0_value.paging = true; // 1 << 31
    cr0_value.write();

    // Assert that long mode is active.
    std.debug.assert(zasm.Efer.read().long_mode_active);
}
