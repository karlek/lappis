extern exception_handler
extern warn_interrupt
extern keyboard_handler
extern mouse_handler
extern ata_handler

isr_double_fault:
	; Double fault
	mov rdi, 8
	call warn_interrupt
	call exception_handler
	iretq

isr_general_protection_fault:
	; Page fault
	mov rdi, 0xd
	call warn_interrupt
	call exception_handler
	iretq

isr_page_fault:
	; Page fault
	mov rdi, 0xe
	call warn_interrupt
	call exception_handler
	iretq

irq_timer:
	; Timer interrupt.
	push ax
	; End of interrupt.
	mov al, 0x20
    out 0x20, al
    pop ax
	iretq

irq_keyboard:
	; iretq
	push rax     ; Make sure you don't damage current state.
	; in al, 0x60  ; Read information from the keyboard.
	; mov rdi, rax  ; Save the information.
	call keyboard_handler
	pop rax
	iretq

irq_mouse:
	push rax     ; Make sure you don't damage current state.
	call mouse_handler
	pop rax
	iretq

irq_primary_ata:
	push rax     ; Make sure you don't damage current state.
	call ata_handler
	pop rax
	iretq

irq_secondary_ata:
	push rax     ; Make sure you don't damage current state.
	call ata_handler
	pop rax
	iretq

%macro not_implemented 1
not_implemented_%1:
	; Save exception code.
	mov rdi, %1
	call warn_interrupt
	hlt
	nop
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
	dq 0
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
	dq 0
	; 23 Reserved
	dq 0
	; 24 Reserved
	dq 0
	; 25 Reserved
	dq 0
	; 26 Reserved
	dq 0
	; 27 Reserved
	dq 0
	; 28 Hypervisor Injection Exception
	dq not_implemented_28
	; 29 VMM Communication Exception
	dq not_implemented_29
	; 30 Security Exception
	dq not_implemented_30
	; 31 Reserved
	dq 0
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
