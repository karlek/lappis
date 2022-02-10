extern exception_handler
extern warn_interrupt

isr_double_fault:
	; Double fault
	mov rdi, 8
	call warn_interrupt
	call exception_handler
	iretq

isr_page_fault:
	; Page fault
	mov rdi, 0xe
	call warn_interrupt
	call exception_handler
	iretq

%macro not_implemented 1
not_implemented_%1:
	; Save exception code.
	mov rdi, %1
	call warn_interrupt
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
not_implemented 13
not_implemented 16
not_implemented 17
not_implemented 18
not_implemented 19
not_implemented 20
not_implemented 21
not_implemented 28
not_implemented 29
not_implemented 30

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
	dq not_implemented_13
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
