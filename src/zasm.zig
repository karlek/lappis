// MIT License
//
// Copyright (c) 2020-2022 Lee Cannon

const std = @import("std");

// ~~~ [ zig-x86_64/src/registers/control.zig ] ~~~

/// Various control flags modifying the basic operation of the CPU.
pub const Cr0 = packed struct {
    /// Enables protected mode.
    protected_mode: bool,

    /// Enables monitoring of the coprocessor, typical for x87 instructions.
    ///
    /// Controls together with the `task_switched` flag whether a `wait` or `fwait`
    /// instruction should cause an `#NE` exception.
    monitor_coprocessor: bool,

    /// Force all x87 and MMX instructions to cause an `#NE` exception.
    emulate_coprocessor: bool,

    /// Automatically set to 1 on _hardware_ task switch.
    ///
    /// This flags allows lazily saving x87/MMX/SSE instructions on hardware context switches.
    task_switched: bool,

    /// Indicates support of 387DX math coprocessor instructions.
    ///
    /// Always set on all recent x86 processors, cannot be cleared.
    extension_type: bool,

    /// Enables the native (internal) error reporting mechanism for x87 FPU errors.
    numeric_error: bool,

    z_reserved6_15: u10,

    /// Controls whether supervisor-level writes to read-only pages are inhibited.
    ///
    /// When set, it is not possible to write to read-only pages from ring 0.
    write_protect: bool,

    z_reserved17: bool,

    /// Enables automatic usermode alignment checking if `RFlags.alignment_check` is also set.
    alignment_mask: bool,

    z_reserved19_28: u10,

    /// Ignored. Used to control write-back/write-through cache strategy on older CPUs.
    not_write_through: bool,

    /// Disables some processor caches, specifics are model-dependent.
    cache_disable: bool,

    /// Enables paging.
    ///
    /// If this bit is set, `protected_mode` must be set.
    paging: bool,

    z_reserved32_63: u32,

    /// Read the current set of CR0 flags.
    pub fn read() Cr0 {
        return Cr0.fromU64(readRaw());
    }

    /// Read the current raw CR0 value.
    fn readRaw() u64 {
        return asm ("mov %%cr0, %[ret]"
            : [ret] "=r" (-> u64),
        );
    }

    /// Write CR0 flags.
    ///
    /// Preserves the value of reserved fields.
    pub fn write(self: Cr0) void {
        writeRaw(self.toU64() | (readRaw() & ALL_RESERVED));
    }

    /// Write raw CR0 flags.
    ///
    /// Does _not_ preserve any values, including reserved fields.
    fn writeRaw(value: u64) void {
        asm volatile ("mov %[val], %%cr0"
            :
            : [val] "r" (value),
            : "memory"
        );
    }

    const ALL_RESERVED: u64 = blk: {
        var flags = std.mem.zeroes(Cr0);
        flags.z_reserved6_15 = std.math.maxInt(u10);
        flags.z_reserved17 = true;
        flags.z_reserved19_28 = std.math.maxInt(u10);
        flags.z_reserved32_63 = std.math.maxInt(u32);
        break :blk @bitCast(u64, flags);
    };

    const ALL_NOT_RESERVED: u64 = ~ALL_RESERVED;

    pub fn fromU64(value: u64) Cr0 {
        return @bitCast(Cr0, value & ALL_NOT_RESERVED);
    }

    pub fn toU64(self: Cr0) u64 {
        return @bitCast(u64, self) & ALL_NOT_RESERVED;
    }

    test {
        try std.testing.expectEqual(@as(usize, 64), @bitSizeOf(Cr0));
        try std.testing.expectEqual(@as(usize, 8), @sizeOf(Cr0));
        try std.testing.expectEqual(@as(usize, 0b11100000000001010000000000111111), ALL_NOT_RESERVED);
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// Contains the physical address of the highest-level page table.
pub const Cr3 = struct {
    pub const Contents = struct {
        phys_frame: PhysFrame,
        cr3_flags: Cr3Flags,

        pub fn toU64(self: Contents) u64 {
            return self.phys_frame.start_address.value | self.cr3_flags.toU64();
        }
    };

    pub const PcidContents = struct {
        phys_frame: PhysFrame,
        pcid: Pcid,

        pub fn toU64(self: PcidContents) u64 {
            return self.phys_frame.start_address.value | @as(u64, self.pcid.value);
        }
    };

    /// Read the current P4 table address from the CR3 register.
    pub fn read() Contents {
        const value = readRaw();

        return .{
            .phys_frame = PhysFrame.containingAddress(
                // unchecked is fine as the mask ensures validity
                PhysAddr.initUnchecked(value & 0x000f_ffff_ffff_f000),
            ),
            .cr3_flags = Cr3Flags.fromU64(value),
        };
    }

    /// Read the raw value from the CR3 register
    fn readRaw() u64 {
        return asm ("mov %%cr3, %[value]"
            : [value] "=r" (-> u64),
        );
    }

    /// Read the current P4 table address from the CR3 register along with PCID.
    /// The correct functioning of this requires Cr4.pcid = 1.
    /// See [`Cr4.pcid`]
    pub fn readPcid() PcidContents {
        const value = readRaw();

        return .{
            .phys_frame = PhysFrame.containingAddress(
                // unchecked is fine as the mask ensures validity
                PhysAddr.initUnchecked(value & 0x000f_ffff_ffff_f000),
            ),
            .pcid = Pcid.init(@truncate(u12, value & 0xFFF)),
        };
    }

    /// Write a new P4 table address into the CR3 register.
    pub fn write(contents: Contents) void {
        writeRaw(contents.toU64());
    }

    /// Write a new P4 table address into the CR3 register.
    ///
    /// ## Safety
    /// Changing the level 4 page table is unsafe, because it's possible to violate memory safety by
    /// changing the page mapping.
    /// [`Cr4.pcid`] must be set before calling this method.
    pub fn writePcid(pcidContents: PcidContents) void {
        writeRaw(pcidContents.toU64());
    }

    fn writeRaw(value: u64) void {
        asm volatile ("mov %[value], %%cr3"
            :
            : [value] "r" (value),
            : "memory"
        );
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// Controls cache settings for the highest-level page table.
///
/// Unused if paging is disabled or if `Cr4.pcid` is enabled.
pub const Cr3Flags = packed struct {
    z_reserved0: bool,
    z_reserved1: bool,

    /// Use a writethrough cache policy for the table (otherwise a writeback policy is used).
    page_level_writethrough: bool,

    /// Disable caching for the table.
    page_level_cache_disable: bool,

    z_reserved4_63: u60,

    const ALL_RESERVED: u64 = blk: {
        var flags = std.mem.zeroes(Cr3Flags);
        flags.z_reserved0 = true;
        flags.z_reserved1 = true;
        flags.z_reserved4_63 = std.math.maxInt(u60);
        break :blk @bitCast(u64, flags);
    };

    const ALL_NOT_RESERVED: u64 = ~ALL_RESERVED;

    pub fn fromU64(value: u64) Cr3Flags {
        return @bitCast(Cr3Flags, value & ALL_NOT_RESERVED);
    }

    pub fn toU64(self: Cr3Flags) u64 {
        return @bitCast(u64, self) & ALL_NOT_RESERVED;
    }

    test {
        try std.testing.expectEqual(@as(usize, 64), @bitSizeOf(Cr3Flags));
        try std.testing.expectEqual(@as(usize, 8), @sizeOf(Cr3Flags));
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// Contains various control flags that enable architectural extensions, and indicate support for specific processor capabilities.
pub const Cr4 = packed struct {
    /// Enables hardware-supported performance enhancements for software running in
    /// virtual-8086 mode.
    virtual_8086_mode_extensions: bool,

    /// Enables support for protected-mode virtual interrupts.
    protected_mode_virtual_interrupts: bool,

    /// When set, only privilege-level 0 can execute the RDTSC or RDTSCP instructions.
    timestamp_disable: bool,

    /// Enables I/O breakpoint capability and enforces treatment of DR4 and DR5 x86_64 registers
    /// as reserved.
    debugging_extensions: bool,

    /// Enables the use of 4MB physical frames; ignored in long mode.
    page_size_extension: bool,

    /// Enables physical address extensions and 2MB physical frames. Required in long mode.
    physical_address_extension: bool,

    /// Enables the machine-check exception mechanism.
    machine_check_exception: bool,

    /// Enables the global page feature, allowing some page translations to be marked as global (see `PageTableFlags.global`).
    page_global: bool,

    /// Allows software running at any privilege level to use the RDPMC instruction.
    performance_monitor_counter: bool,

    /// Enables the use of legacy SSE instructions; allows using FXSAVE/FXRSTOR for saving
    /// processor state of 128-bit media instructions.
    osfxsr: bool,

    /// Enables the SIMD floating-point exception (#XF) for handling unmasked 256-bit and
    /// 128-bit media floating-point errors.
    osxmmexcpt_enable: bool,

    /// Prevents the execution of the SGDT, SIDT, SLDT, SMSW, and STR instructions by
    /// user-mode software.
    user_mode_instruction_prevention: bool,

    /// Enables 5-level paging on supported CPUs (Intel Only).
    l5_paging: bool,

    /// Enables VMX instructions (Intel Only).
    virtual_machine_extensions: bool,

    /// Enables SMX instructions (Intel Only).
    safer_mode_extensions: bool,

    /// Enables software running in 64-bit mode at any privilege level to read and write
    /// the FS.base and GS.base hidden segment register state.
    fsgsbase: bool,

    z_reserved16: bool,

    /// Enables process-context identifiers (PCIDs).
    pcid: bool,

    /// Enables extended processor state management instructions, including XGETBV and XSAVE.
    osxsave: bool,

    //// Enables the Key Locker feature (Intel Only).
    ///
    /// This enables creation and use of opaque AES key handles; see the
    /// [Intel Key Locker Specification](https://software.intel.com/content/www/us/en/develop/download/intel-key-locker-specification.html)
    /// for more information.
    key_locker: bool,

    /// Prevents the execution of instructions that reside in pages accessible by user-mode
    /// software when the processor is in supervisor-mode.
    supervisor_mode_execution_prevention: bool,

    /// Enables restrictions for supervisor-mode software when reading data from user-mode
    /// pages.
    supervisor_mode_access_prevention: bool,

    /// Enables protection keys for user-mode pages.
    ///
    /// Also enables access to the PKRU register (via the `RDPKRU`/`WRPKRU` instructions) to set user-mode protection key access
    /// controls.
    protection_key_user: bool,

    /// Enables Control-flow Enforcement Technology (CET)
    ///
    /// This enables the shadow stack feature, ensuring return addresses read via `RET` and `IRET` have not been corrupted.
    control_flow_enforcement: bool,

    /// Enables protection keys for supervisor-mode pages (Intel Only).
    ///
    /// Also enables the `IA32_PKRS` MSR to set supervisor-mode protection key access controls.
    protection_key_supervisor: bool,

    z_reserved25_31: u7,
    z_reserved32_63: u32,

    /// Read the current set of CR4 flags.
    pub fn read() Cr4 {
        return Cr4.fromU64(readRaw());
    }

    /// Read the current raw CR4 value.
    fn readRaw() u64 {
        return asm ("mov %%cr4, %[ret]"
            : [ret] "=r" (-> u64),
        );
    }

    /// Write CR4 flags.
    ///
    /// Preserves the value of reserved fields.
    pub fn write(self: Cr4) void {
        writeRaw(self.toU64() | (readRaw() & ALL_RESERVED));
    }

    /// Write raw CR4 flags.
    ///
    /// Does _not_ preserve any values, including reserved fields.
    fn writeRaw(value: u64) void {
        asm volatile ("mov %[val], %%cr4"
            :
            : [val] "r" (value),
            : "memory"
        );
    }

    const ALL_RESERVED: u64 = blk: {
        var flags = std.mem.zeroes(Cr4);
        flags.z_reserved16 = true;
        flags.z_reserved25_31 = std.math.maxInt(u7);
        flags.z_reserved32_63 = std.math.maxInt(u32);
        break :blk @bitCast(u64, flags);
    };

    const ALL_NOT_RESERVED: u64 = ~ALL_RESERVED;

    pub fn fromU64(value: u64) Cr4 {
        return @bitCast(Cr4, value & ALL_NOT_RESERVED);
    }

    pub fn toU64(self: Cr4) u64 {
        return @bitCast(u64, self) & ALL_NOT_RESERVED;
    }

    test {
        try std.testing.expectEqual(@as(usize, 64), @bitSizeOf(Cr4));
        try std.testing.expectEqual(@as(usize, 8), @sizeOf(Cr4));
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

// ~~~ [ zig-x86_64/src/registers/model_specific.zig ] ~~~

/// The Extended Feature Enable Register.
pub const Efer = packed struct {
    /// Enables the `syscall` and `sysret` instructions.
    system_call_extensions: bool,

    z_reserved1_7: u7,

    /// Activates long mode, requires activating paging.
    long_mode_enable: bool,

    z_reserved9: bool,

    /// Indicates that long mode is active.
    long_mode_active: bool,

    /// Enables the no-execute page-protection feature.
    no_execute_enable: bool,

    /// Enables SVM extensions.
    secure_virtual_machine_enable: bool,

    /// Enable certain limit checks in 64-bit mode.
    long_mode_segment_limit: bool,

    /// Enable the `fxsave` and `fxrstor` instructions to execute faster in 64-bit mode.
    fast_fxsave_fxrstor: bool,

    /// Changes how the `invlpg` instruction operates on TLB entries of upper-level entries.
    translation_cache_extension: bool,

    z_reserved16_31: u16,
    z_reserved32_63: u32,

    /// Read the current EFER flags.
    pub fn read() Efer {
        return Efer.fromU64(REGISTER.read());
    }

    /// Write the EFER flags, preserving reserved values.
    ///
    /// Preserves the value of reserved fields.
    pub fn write(self: Efer) void {
        REGISTER.write(self.toU64() | (REGISTER.read() & ALL_RESERVED));
    }

    const REGISTER = Msr(0xC000_0080);

    const ALL_RESERVED: u64 = blk: {
        var flags = std.mem.zeroes(Efer);
        flags.z_reserved1_7 = std.math.maxInt(u7);
        flags.z_reserved9 = true;
        flags.z_reserved16_31 = std.math.maxInt(u16);
        flags.z_reserved32_63 = std.math.maxInt(u32);
        break :blk @bitCast(u64, flags);
    };

    const ALL_NOT_RESERVED: u64 = ~ALL_RESERVED;

    pub fn fromU64(value: u64) Efer {
        return @bitCast(Efer, value & ALL_NOT_RESERVED);
    }

    pub fn toU64(self: Efer) u64 {
        return @bitCast(u64, self) & ALL_NOT_RESERVED;
    }

    test {
        try std.testing.expectEqual(@as(usize, 64), @bitSizeOf(Efer));
        try std.testing.expectEqual(@as(usize, 8), @sizeOf(Efer));
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

fn Msr(comptime register: u32) type {
    return struct {
        pub inline fn read() u64 {
            var high: u32 = undefined;
            var low: u32 = undefined;

            asm volatile ("rdmsr"
                : [low] "={eax}" (low),
                  [high] "={edx}" (high),
                : [reg] "{ecx}" (register),
                : "memory"
            );

            return (@as(u64, high) << 32) | @as(u64, low);
        }

        pub inline fn write(value: u64) void {
            asm volatile ("wrmsr"
                :
                : [reg] "{ecx}" (register),
                  [low] "{eax}" (@truncate(u32, value)),
                  [high] "{edx}" (@truncate(u32, value >> 32)),
                : "memory"
            );
        }

        comptime {
            std.testing.refAllDecls(@This());
        }
    };
}

// ~~~ [ zig-x86_64/src/structures/paging/frame.zig ] ~~~

/// A physical memory frame. Page size 4 KiB
pub const PhysFrame = extern struct {
    const size: PageSize = .Size4KiB;

    start_address: PhysAddr,

    /// Returns the frame that starts at the given physical address.
    ///
    /// Returns an error if the address is not correctly aligned (i.e. is not a valid frame start)
    pub fn fromStartAddress(address: PhysAddr) PhysFrameError!PhysFrame {
        if (!address.isAligned(size.bytes())) {
            return PhysFrameError.AddressNotAligned;
        }
        return fromStartAddressUnchecked(address);
    }

    /// Returns the frame that starts at the given physical address.
    /// Without validaing the addresses alignment
    pub fn fromStartAddressUnchecked(address: PhysAddr) PhysFrame {
        return .{ .start_address = address };
    }

    /// Returns the frame that contains the given physical address.
    pub fn containingAddress(address: PhysAddr) PhysFrame {
        return .{
            .start_address = address.alignDown(@intCast(usize, size.bytes())),
        };
    }

    /// Returns the size of the frame (4KB, 2MB or 1GB).
    pub fn sizeOf(self: PhysFrame) u64 {
        _ = self;
        return size.bytes();
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

pub const PhysFrameError = error{AddressNotAligned};

// ~~~ [ zig-x86_64/src/addr.zig ] ~~~

/// A 64-bit physical memory address.
///
/// On `x86_64`, only the 52 lower bits of a physical address can be used. The top 12 bits need
/// to be zero. This type guarantees that it always represents a valid physical address.
pub const PhysAddr = packed struct {
    value: u64,

    /// Tries to create a new physical address.
    ///
    /// Fails if any bits in the range 52 to 64 are set.
    pub fn init(addr: u64) error{PhysAddrNotValid}!PhysAddr {
        return switch (getBits(addr, 52, 12)) {
            0 => PhysAddr{ .value = addr },
            else => return error.PhysAddrNotValid,
        };
    }

    /// Creates a new physical address.
    ///
    /// ## Panics
    /// This function panics if a bit in the range 52 to 64 is set.
    pub fn initPanic(addr: u64) PhysAddr {
        return init(addr) catch @panic("physical addresses must not have any bits in the range 52 to 64 set");
    }

    const TRUNCATE_CONST: u64 = 1 << 52;

    /// Creates a new physical address, throwing bits 52..64 away.
    pub fn initTruncate(addr: u64) PhysAddr {
        return PhysAddr{ .value = addr % TRUNCATE_CONST };
    }

    /// Creates a new physical address, without any checks.
    pub fn initUnchecked(addr: u64) PhysAddr {
        return .{ .value = addr };
    }

    /// Creates a physical address that points to `0`.
    pub fn zero() PhysAddr {
        return .{ .value = 0 };
    }

    /// Convenience method for checking if a physical address is null.
    pub fn isNull(self: PhysAddr) bool {
        return self.value == 0;
    }

    /// Aligns the physical address upwards to the given alignment.
    /// The alignment must be a power of 2 and greater than 0.
    pub fn alignUp(self: PhysAddr, alignment: usize) PhysAddr {
        return .{ .value = std.mem.alignForward(self.value, alignment) };
    }

    /// Aligns the physical address downwards to the given alignment.
    /// The alignment must be a power of 2 and greater than 0.
    pub fn alignDown(self: PhysAddr, alignment: usize) PhysAddr {
        return .{ .value = std.mem.alignBackward(@intCast(usize, self.value), alignment) };
    }

    /// Checks whether the physical address has the given alignment.
    /// The alignment must be a power of 2 and greater than 0.
    pub fn isAligned(self: PhysAddr, alignment: usize) bool {
        return std.mem.isAligned(self.value, alignment);
    }

    test {
        std.testing.refAllDecls(@This());
        try std.testing.expectEqual(@bitSizeOf(u64), @bitSizeOf(PhysAddr));
        try std.testing.expectEqual(@sizeOf(u64), @sizeOf(PhysAddr));
    }
};

// ~~~ [ zig-x86_64/src/stuctures/paging/page.zig ] ~~~

const SIZE_4KiB_STR: []const u8 = "4KiB";
const SIZE_2MiB_STR: []const u8 = "2MiB";
const SIZE_1GiB_STR: []const u8 = "1GiB";

pub const PageSize = enum {
    Size4KiB,
    Size2MiB,
    Size1GiB,

    pub fn bytes(self: PageSize) u64 {
        return switch (self) {
            .Size4KiB => 4096,
            .Size2MiB => 4096 * 512,
            .Size1GiB => 4096 * 512 * 512,
        };
    }

    pub fn sizeString(self: PageSize) []const u8 {
        return switch (self) {
            .Size4KiB => SIZE_4KiB_STR,
            .Size2MiB => SIZE_2MiB_STR,
            .Size1GiB => SIZE_1GiB_STR,
        };
    }

    pub fn isGiantPage(self: PageSize) bool {
        return self == .Size1GiB;
    }
};

// ~~~ [ zig-x86_64/src/instructions/tlb.zig ] ~~~

/// Structure of a PCID. A PCID has to be <= 4096 for x86_64.
pub const Pcid = packed struct {
    value: u12,

    /// Create a new PCID
    pub fn init(pcid: u12) Pcid {
        return .{
            .value = pcid,
        };
    }
};

// ~~~ [ zig-x86_64/src/structures/paging/page_table.zig ] ~~~

/// A 64-bit page table entry.
pub const PageTableEntry = packed struct {
    entry: u64,

    /// Creates an unused page table entry.
    pub fn init() PageTableEntry {
        return .{ .entry = 0 };
    }

    /// Returns whether this entry is zero.
    pub fn isUnused(self: PageTableEntry) bool {
        return self.entry == 0;
    }

    /// Sets this entry to zero.
    pub fn setUnused(self: *PageTableEntry) void {
        self.entry = 0;
    }

    /// Returns the flags of this entry.
    pub fn getFlags(self: PageTableEntry) PageTableFlags {
        return PageTableFlags.fromU64(self.entry);
    }

    /// Returns the physical address mapped by this entry, might be zero.
    pub fn getAddr(self: PageTableEntry) PhysAddr {
        // Unchecked is used as the mask ensures validity
        return PhysAddr.initUnchecked(self.entry & 0x000f_ffff_ffff_f000);
    }

    /// Returns the physical frame mapped by this entry.
    ///
    /// Returns the following errors:
    ///
    /// - `FrameError::FrameNotPresent` if the entry doesn't have the `present` flag set.
    /// - `FrameError::HugeFrame` if the entry has the `huge_page` flag set (for huge pages the
    ///    `addr` function must be used)
    pub fn getFrame(self: PageTableEntry) FrameError!PhysFrame {
        const flags = self.getFlags();

        if (!flags.present) {
            return FrameError.FrameNotPresent;
        }

        if (flags.huge) {
            return FrameError.HugeFrame;
        }

        return PhysFrame.containingAddress(self.getAddr());
    }

    /// Map the entry to the specified physical address
    pub fn setAddr(self: *PageTableEntry, addr: PhysAddr) void {
        // TODO: re-enable assert.
        //std.debug.assert(addr.isAligned(PageSize.Size4KiB.bytes()));
        self.entry = addr.value | self.getFlags().toU64();
    }

    /// Map the entry to the specified physical frame with the specified flags.
    pub fn setFrame(self: *PageTableEntry, frame: PhysFrame, flags: PageTableFlags) void {
        std.debug.assert(!self.getFlags().huge);
        self.setAddr(frame.start_address);
        self.setFlags(flags);
    }

    /// Sets the flags of this entry.
    pub fn setFlags(self: *PageTableEntry, flags: PageTableFlags) void {
        self.entry = self.getAddr().value | flags.toU64();
    }

    test {
        std.testing.refAllDecls(@This());
        try std.testing.expectEqual(@bitSizeOf(u64), @bitSizeOf(PageTableEntry));
        try std.testing.expectEqual(@sizeOf(u64), @sizeOf(PageTableEntry));
    }
};

pub const PageTableFlags = packed struct {
    /// Specifies whether the mapped frame or page table is loaded in memory.
    present: bool = false,

    /// Controls whether writes to the mapped frames are allowed.
    ///
    /// If this bit is unset in a level 1 page table entry, the mapped frame is read-only.
    /// If this bit is unset in a higher level page table entry the complete range of mapped
    /// pages is read-only.
    writeable: bool = false,

    /// Controls whether accesses from userspace (i.e. ring 3) are permitted.
    user_accessible: bool = false,

    /// If this bit is set, a “write-through” policy is used for the cache, else a “write-back”
    /// policy is used.
    write_through: bool = false,

    /// Disables caching for the pointed entry is cacheable.
    no_cache: bool = false,

    /// Set by the CPU when the mapped frame or page table is accessed.
    accessed: bool = false,

    /// Set by the CPU on a write to the mapped frame.
    dirty: bool = false,

    /// Specifies that the entry maps a huge frame instead of a page table. Only allowed in
    /// P2 or P3 tables.
    huge: bool = false,

    /// Indicates that the mapping is present in all address spaces, so it isn't flushed from
    /// the TLB on an address space switch.
    global: bool = false,

    /// Available to the OS, can be used to store additional data, e.g. custom flags.
    bit_9_11: u3 = 0,

    z_reserved12_15: u4 = 0,
    z_reserved16_47: u32 = 0,
    z_reserved48_51: u4 = 0,

    /// Available to the OS, can be used to store additional data, e.g. custom flags.
    bit_52_62: u11 = 0,

    /// Forbid code execution from the mapped frames.
    ///
    /// Can be only used when the no-execute page protection feature is enabled in the EFER
    /// register.
    no_execute: bool = false,

    pub fn sanitizeForParent(self: PageTableFlags) PageTableFlags {
        var parent_flags = PageTableFlags{};
        if (self.present) parent_flags.present = true;
        if (self.writeable) parent_flags.writeable = true;
        if (self.user_accessible) parent_flags.user_accessible = true;
        return parent_flags;
    }

    pub fn fromU64(value: u64) PageTableFlags {
        return @bitCast(PageTableFlags, value & ALL_NOT_RESERVED);
    }

    pub fn toU64(self: PageTableFlags) u64 {
        return @bitCast(u64, self) & ALL_NOT_RESERVED;
    }

    const ALL_RESERVED: u64 = blk: {
        var flags = std.mem.zeroes(PageTableFlags);
        flags.z_reserved12_15 = std.math.maxInt(u4);
        flags.z_reserved16_47 = std.math.maxInt(u32);
        flags.z_reserved48_51 = std.math.maxInt(u4);
        break :blk @bitCast(u64, flags);
    };

    const ALL_NOT_RESERVED: u64 = ~ALL_RESERVED;

    test {
        try std.testing.expectEqual(@bitSizeOf(u64), @bitSizeOf(PageTableFlags));
        try std.testing.expectEqual(@sizeOf(u64), @sizeOf(PageTableFlags));
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// The error returned by the `PageTableEntry::frame` method.
pub const FrameError = error{
    /// The entry does not have the `present` flag set, so it isn't currently mapped to a frame.
    FrameNotPresent,
    /// The entry does have the `huge_page` flag set. The `frame` method has a standard 4KiB frame
    /// as return type, so a huge frame can't be returned.
    HugeFrame,
};

// ~~~ [ zig-bitjuggle/bitjuggle.zig ] ~~~

/// Obtains the `number_of_bits` bits starting at `start_bit`
/// Where `start_bit` is the lowest significant bit to fetch
///
/// ```zig
/// const a: u8 = 0b01101100;
/// const b = getBits(a, 2, 4);
/// try testing.expectEqual(@as(u4,0b1011), b);
/// ```
pub fn getBits(target: anytype, comptime start_bit: comptime_int, comptime number_of_bits: comptime_int) std.meta.Int(.unsigned, number_of_bits) {
    const TargetType = @TypeOf(target);
    const ReturnType = std.meta.Int(.unsigned, number_of_bits);

    comptime {
        if (number_of_bits == 0) @compileError("non-zero number_of_bits must be provided");

        if (@typeInfo(TargetType) == .Int) {
            if (@typeInfo(TargetType).Int.signedness != .unsigned) {
                @compileError("requires an unsigned integer, found " ++ @typeName(TargetType));
            }
            if (start_bit >= @bitSizeOf(TargetType)) {
                @compileError("start_bit index is out of bounds of the bit field");
            }
            if (start_bit + number_of_bits > @bitSizeOf(TargetType)) {
                @compileError("start_bit + number_of_bits is out of bounds of the bit field");
            }
        } else if (@typeInfo(TargetType) == .ComptimeInt) {
            if (target < 0) {
                @compileError("requires an unsigned integer, found " ++ @typeName(TargetType));
            }
        } else {
            @compileError("requires an unsigned integer, found " ++ @typeName(TargetType));
        }
    }

    return @truncate(ReturnType, target >> start_bit);
}
