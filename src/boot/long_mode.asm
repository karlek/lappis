section .rodata
gdt64:
	dq 0 ; Zero entry
.code: equ $ - gdt64
	; [Descriptor type, present, executable, long mode flag]
	;
	; Descriptor type bit. If clear (0) the descriptor defines a system segment
	; (eg. a Task State Segment). If set (1) it defines a code or data segment.
	;
	; Pr: Present bit. Allows an entry to refer to a valid segment. Must be set
	; (1) for any valid segment.
	;
	; Ex: Executable bit. If clear (0) the descriptor defines a data segment.
	; If set (1) it defines a code segment which can be executed from.
	;
	; L: Long-mode code flag. If set (1), the descriptor defines a 64-bit code
	; segment. When set, Sz should always be clear. For any other type of
	; segment (other code types or any data segment), it should be clear (0).
	;
	; Code segment
	dq (1<<43) | (1<<44) | (1<<47) | (1<<53)
.data: equ $ - gdt64
	dq           (1<<44) | (1<<47) | (1<<53)
.user_code: equ $ - gdt64
	dq (1<<43) | (1<<44) | (1<<45) | (1<<46) | (1<<47) | (1<<53)
.user_data: equ $ - gdt64
	dq           (1<<44) | (1<<45) | (1<<46) | (1<<47) | (1<<53)
; .tss: equ $ - gdt64
; 	dq (1<<41) | (1<<43) |                     (1<<47) | (1<<53)

.tss: equ $ - gdt64
	.limit_low        dw    0
	.base_low         dw    (tss64 - $$) & 0xffff
	.base_middle      db    ((tss64 - $$) >> 16) & 0xff
	.access           db    10001001b
	.limit_high_flags db    00000000b
	.base_high        db    ((tss64 - $$) >> 24) & 0xff
	.base_highest     dd    ((tss64 - $$) >> 32)
	.reserved         dd    0x00000000

; In most systems, the DPLs of TSS descriptors are set to values less than 3,
; so that only privileged software can perform task switching. However, in
; multitasking applications, DPLs for some TSS descriptors may be set to 3 to
; allow task switching at the application (or user) privilege level.

.pointer:
	dw $ - gdt64 - 1
	dq gdt64

tss64:
	.rsp0 dq 0x3000
	.rsp1 dq 0
	.rsp2 dq 0
	.ist1 dq 0x3100
	.ist2 dq 0x3200
	.ist3 dq 0x3300
	.ist4 dq 0
	.ist5 dq 0
	.ist6 dq 0
	.ist7 dq 0
	.iopb dw 0          ; no IOPB

section .text
bits 32
init_long_mode:
	; ebx contains the 32-bit physical address of the Multiboot2 information
	; structure provided by the boot loader.
	mov esp, temp_stack_top
	push ebx

	call set_up_page_tables
	call map_kernel_stack
	call map_frame_buffer

	call enable_paging
	lgdt [gdt64.pointer]

	; Fifth 8-byte selector, symbolically OR-ed with 0 to set the RPL (requested
	; privilege level).
	mov ax, gdt64.tss | 3
	ltr ax

	jmp gdt64.code:long_mode_start

bits 64
long_mode_start:
	; Clear the interrupt flag.
	cli

	; Kernel respects write protection.
	mov rax, cr0
	or rax, CR0_WRITE_PROTECT
	mov cr0, rax

	; Reset registers for sanity.
	mov rax, 0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov rbx, 0
	mov rcx, 0
	mov rdi, 0

	; Fetch that multiboot structure, before we use our new fresh stack.
	pop rdi
	; Set our kernel stack.
	mov rsp, STACK_TOP
	call main

	; A hint that we have escaped the kernel.
	mov rax, 0xdeadbeef
	jmp $

%include "src/boot/paging.asm"
