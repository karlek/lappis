const std = @import("std");
const zasm = @import("zasm.zig");
const paging = @import("paging.zig");

export var p4_table: [512]u64 align(4096) = std.mem.zeroes([512]u64); // [4096]u8
export var p3_table: [512]u64 align(4096) = std.mem.zeroes([512]u64); // [4096]u8
export var p2_table: [512]u64 align(4096) = std.mem.zeroes([512]u64); // [4096]u8

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
    var p3_addr = zasm.PhysAddr.initUnchecked(raw_p3_addr);
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
    // Set address of page table entry.
    const raw_p2_addr = @as(u64, @intCast(@intFromPtr(&p2_table[0])));
    var p2_addr = zasm.PhysAddr.initUnchecked(raw_p2_addr);
    p3_page_table_entry.setAddr(p2_addr);
    // Set page table entry.
    p3_table[0] = p3_page_table_entry.entry;
}

export fn map_kernel_code_segment() void {
    var page_table_entry = zasm.PageTableEntry.init();
    // Set flags `present`, `writeable`, `user accessible` and `page size`.
    // Note, `no execute` is not set.
    var page_table_flags = page_table_entry.getFlags();
    page_table_flags.present = true;
    page_table_flags.writeable = true; // TODO: unset writeable and set no_execute for kernel code segment?
    page_table_flags.user_accessible = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).
    // Make only the range 0x000000-0x200000 (2MiB) executable.
    //page_table_flags.no_execute = true;
    page_table_entry.setFlags(page_table_flags);
    // Map pages of kernel code segment in P2 table.
    const p2_index_offset = paging.P2_KERNEL_CODE_FIRST_INDEX; // page index offset into P2 table of kernel code segment pages.
    const kernel_code_seg_base_addr = p2_index_offset * paging.page_size;
    var page_num: usize = 0;
    while (page_num < paging.NUM_KERNEL_CODE_PAGES) : (page_num += 1) {
        // Set address of page table entry.
        var kernel_code_seg_page_offset = page_num * paging.page_size; // offset from start of kernel code segment.
        var addr = zasm.PhysAddr.initUnchecked(kernel_code_seg_base_addr + kernel_code_seg_page_offset);
        page_table_entry.setAddr(addr);
        // Set page table entry.
        var p2_index = page_num + p2_index_offset;
        p2_table[p2_index] = page_table_entry.entry;
    }
}

export fn map_kernel_data_segment() void {
    var page_table_entry = zasm.PageTableEntry.init();
    // Set flags `present`, `writeable`, `user accessible`, `page size` and
    // `no execute`.
    var page_table_flags = page_table_entry.getFlags();
    page_table_flags.present = true;
    page_table_flags.writeable = true;
    page_table_flags.user_accessible = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).
    page_table_flags.no_execute = true;
    page_table_entry.setFlags(page_table_flags);
    // Map pages of kernel data segment in P2 table.
    const p2_index_offset = paging.P2_KERNEL_DATA_FIRST_INDEX; // page index offset into P2 table of kernel data segment pages.
    const kernel_data_seg_base_addr = p2_index_offset * paging.page_size;
    var page_num: usize = 0;
    while (page_num < paging.NUM_KERNEL_DATA_PAGES) : (page_num += 1) {
        // Set address of page table entry.
        var kernel_data_seg_page_offset = page_num * paging.page_size; // offset from start of kernel data segment.
        var addr = zasm.PhysAddr.initUnchecked(kernel_data_seg_base_addr + kernel_data_seg_page_offset);
        page_table_entry.setAddr(addr);
        // Set page table entry.
        var p2_index = page_num + p2_index_offset;
        p2_table[p2_index] = page_table_entry.entry;
    }
}

export fn map_kernel_stack() void {
    var page_table_entry = zasm.PageTableEntry.init();
    // Set flags `present`, `writeable`, `user accessible`, `page size` and
    // `no execute`. Note, `writeable` is only set for non-guard pages.
    var page_table_flags = page_table_entry.getFlags();
    page_table_flags.present = true;
    page_table_flags.user_accessible = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).
    page_table_flags.no_execute = true;
    // Map pages of kernel stack in P2 table.
    const p2_index_offset = paging.P2_KERNEL_STACK_FIRST_INDEX; // page index offset into P2 table of kernel stack pages.
    const kernel_stack_base_addr = p2_index_offset * paging.page_size;
    var page_num: usize = 0;
    while (page_num < paging.NUM_KERNEL_STACK_PAGES) : (page_num += 1) {
        // Make first and last pages `guard` pages by removing `writeable`.
        if (page_num == 0 or page_num == paging.NUM_KERNEL_STACK_PAGES - 1) {
            page_table_flags.writeable = false;
        } else {
            page_table_flags.writeable = true;
        }
        page_table_entry.setFlags(page_table_flags);
        // Set address of page table entry.
        var kernel_stack_page_offset = page_num * paging.page_size; // offset from start of kernel stack.
        var addr = zasm.PhysAddr.initUnchecked(kernel_stack_base_addr + kernel_stack_page_offset);
        page_table_entry.setAddr(addr);
        // Set page table entry.
        var p2_index = page_num + p2_index_offset;
        p2_table[p2_index] = page_table_entry.entry;
    }
}

export fn map_frame_buffer() void {
    var page_table_entry = zasm.PageTableEntry.init();
    // Set flags `present`, `writeable`, `user accessible`, `page size` and
    // `no execute`.
    var page_table_flags = page_table_entry.getFlags();
    page_table_flags.present = true;
    page_table_flags.writeable = true;
    page_table_flags.user_accessible = true;
    page_table_flags.huge = true; // entry maps to a 2 MB frame (rather than a page table).
    page_table_flags.no_execute = true;
    page_table_entry.setFlags(page_table_flags);
    // Map pages of frame buffer in P2 table.
    const p2_index_offset = paging.P2_FRAME_BUFFER_FIRST_INDEX; // page index offset into P2 table of frame buffer pages.
    // TODO: parse frame buffer pointer from Multiboot2 information
    // structure provided by the boot loader.

    // Start mapping the frame buffer at address 0xFD000000.
    const frame_buffer_base_addr = 0xFD000000;
    var page_num: usize = 0;
    while (page_num < paging.NUM_FRAME_BUFFER_PAGES) : (page_num += 1) {
        // Set address of page table entry.
        var frame_buffer_page_offset = page_num * paging.page_size; // offset from start of frame buffer.
        var addr = zasm.PhysAddr.initUnchecked(frame_buffer_base_addr + frame_buffer_page_offset);
        page_table_entry.setAddr(addr);
        // Set page table entry.
        var p2_index = page_num + p2_index_offset;
        p2_table[p2_index] = page_table_entry.entry;
    }
}

export fn enable_paging() void {
    // Load P4 to CR3 register. (CPU uses this to access the P4 table).
    const raw_p4_addr = @as(u64, @intCast(@intFromPtr(&p4_table[0])));
    var p4_addr = zasm.PhysAddr.initUnchecked(raw_p4_addr);
    var cr3_value = zasm.Cr3.Contents{
        .phys_frame = zasm.PhysFrame.fromStartAddressUnchecked(p4_addr),
        .cr3_flags = zasm.Cr3Flags.fromU64(0),
    };
    zasm.Cr3.write(cr3_value);

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

    // Enable paging in the CR0 register.
    var cr0_value = zasm.Cr0.read();
    cr0_value.paging = true; // 1 << 31
    cr0_value.write();
}
