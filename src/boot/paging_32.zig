const zasm = @import("zasm");

extern var p4_table: [4096]u8;

export fn enable_paging() void {
    // Load P4 to CR3 register. (CPU uses this to access the P4 table).
    const raw_p4_addr = @intCast(u64, @ptrToInt(&p4_table[0]));
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
