bits 64

; Interrupt Gates, interrupts are automatically disabled upon entry and reenabled upon IRET

extern exception_handler
extern warn_interrupt
extern keyboard_handler
extern mouse_handler
extern ata_primary_handler
extern ata_secondary_handler
extern timer_handler

%macro pushaq 0
	pushfq ; save rflags
	push rdi
	push rsi
	push rdx
	push rcx
	push rax
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
%endmacro

%macro popaq 0
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rax
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	popfq
%endmacro

isr_double_fault:
	pushaq

	mov rdi, 0x8
	call warn_interrupt
	call exception_handler

	popaq
	iretq

isr_general_protection_fault:
	pushaq

	mov rdi, 0xd
	call warn_interrupt
	call exception_handler

	popaq
	iretq

isr_page_fault:
	pushaq

	mov rdi, 0xe
	call warn_interrupt
	call exception_handler

	popaq
	iretq

irq_timer:
	pushaq

	call timer_handler

	popaq
	iretq

irq_keyboard:
	pushaq

	call keyboard_handler

	popaq
	iretq

irq_mouse:
	pushaq

	call mouse_handler

	popaq
	iretq

irq_primary_ata:
	pushaq

	call ata_primary_handler

	popaq
	iretq

irq_secondary_ata:
	pushaq

	call ata_secondary_handler

	popaq
	iretq

%macro reserved 1
reserved_%1:
	pushaq

	mov rdi, %1
	call warn_interrupt

	popaq
	hlt
%endmacro

%macro not_implemented 1
not_implemented_%1:
	pushaq

	mov rdi, %1
	call warn_interrupt

	popaq
	hlt
%endmacro

; Generate the labels.
not_implemented 0
not_implemented 1
not_implemented 2
not_implemented 3
not_implemented 4
not_implemented 5
not_implemented 6
not_implemented 7

not_implemented 9
not_implemented 10
not_implemented 11
not_implemented 12
not_implemented 16
not_implemented 17
not_implemented 18
not_implemented 19
not_implemented 20
not_implemented 21
not_implemented 28
not_implemented 29
not_implemented 30
not_implemented 34
not_implemented 35
not_implemented 36
not_implemented 37
not_implemented 38
not_implemented 39
not_implemented 40
not_implemented 41
not_implemented 42
not_implemented 43
not_implemented 45
not_implemented 46
not_implemented 47

reserved 15
reserved 22
reserved 23
reserved 24
reserved 25
reserved 26
reserved 27
reserved 31

global isr_stub_table
isr_stub_table:
	; 0 Divide-by-zero Error
	dq not_implemented_0
	; 1 Debug
	dq not_implemented_1
	; 2 Non-maskable Interrupt
	dq not_implemented_2
	; 3 Breakpoint
	dq not_implemented_3
	; 4 Overflow
	dq not_implemented_4
	; 5 Bound Range Exceeded
	dq not_implemented_5
	; 6 Invalid Opcode
	dq not_implemented_6
	; 7 Device Not Available
	dq not_implemented_7
	; 8 Double Fault
	dq isr_double_fault
	; 9 Coprocessor Segment Overrun
	dq not_implemented_9
	; 10 Invalid TSS
	dq not_implemented_10
	; 11 Segment Not Present
	dq not_implemented_11
	; 12 Stack-Segment Fault
	dq not_implemented_12
	; 13 General Protection Fault
	dq isr_general_protection_fault
	; 14 Page Fault
	dq isr_page_fault
	; 15 Reserved
	dq reserved_15
	; 16 x87 Floating-Point Exception
	dq not_implemented_16
	; 17 Alignment Check
	dq not_implemented_17
	; 18 Machine Check
	dq not_implemented_18
	; 19 SIMD Floating-Point Exception
	dq not_implemented_19
	; 20 Virtualization Exception
	dq not_implemented_20
	; 21 Control Protection Exception
	dq not_implemented_21
	; 22 Reserved
	dq reserved_22
	; 23 Reserved
	dq reserved_23
	; 24 Reserved
	dq reserved_24
	; 25 Reserved
	dq reserved_25
	; 26 Reserved
	dq reserved_26
	; 27 Reserved
	dq reserved_27
	; 28 Hypervisor Injection Exception
	dq not_implemented_28
	; 29 VMM Communication Exception
	dq not_implemented_29
	; 30 Security Exception
	dq not_implemented_30
	; 31 Reserved
	dq reserved_31
	; 32 Remapped: Programmable Interrupt Timer Interrupt
	dq irq_timer
	; 33 Remapped: Keyboard Interrupt
	dq irq_keyboard
	; 34 Remapped: Cascade
	dq not_implemented_34
	; 35 Remapped: COM2
	dq not_implemented_35
	; 36 Remapped: COM1
	dq not_implemented_36
	; 37 Remapped: LPT2
	dq not_implemented_37
	; 38 Remapped: Floppy Disk
	dq not_implemented_38
	; 39 Remapped: LPT1
	dq not_implemented_39
	; 40 Remapped: CMOS real-time clock
	dq not_implemented_40
	; 41 Remapped: Free for peripherals
	dq not_implemented_41
	; 42 Remapped: Free for peripherals
	dq not_implemented_42
	; 43 Remapped: Free for peripherals
	dq not_implemented_43
	; 44 Remapped: PS2 Mouse
	dq irq_mouse
	; 45 Remapped: FPU
	dq not_implemented_45
	; 46 Remapped: Primary ATA Hard Disk
	dq irq_primary_ata
	; 47 Remapped: Secondary ATA Hard Disk
	dq irq_secondary_ata
