section .rodata

; Base          | Flags | Limit | Access        | Base
; 31         24 | 3   0 | 19 16 | 7           0 | 23         16
; Base                          | Limit
; 15                          0 | 15                          0

; # Access byte

; 7 | 6   5 | 4 | 3 | 2  | 1  | 0
; P |  DPL  | S | E | DC | RW | A

; P: Present bit. Allows an entry to refer to a valid segment. Must be set (1)
; for any valid segment.

; DPL: Descriptor privilege level field. Contains the CPU Privilege level of the
; segment.

; 	0 = highest privilege (kernel), 3 = lowest privilege (user applications).

; S: Descriptor type bit.
; 	If clear (0) the descriptor defines a system segment (eg. a Task State
; 	Segment).
; 	If set (1) it defines a code or data segment.

; E: Executable bit.
; 	If clear (0) the descriptor defines a data segment.
; 	If set (1) it defines a code segment which can be executed from.

; DC: Direction bit/Conforming bit.
; 	For data selectors: Direction bit.
; 		If clear (0) the segment grows up.

; 		If set (1) the segment grows down, ie. the Offset has to be greater
; 		than the Limit.

; 	For code selectors: Conforming bit.
; 		If clear (0) code in this segment can only be executed from the ring
; 		set in Privl.

; 		If set (1) code in this segment can be executed from an equal or lower
; 		privilege level. For example, code in ring 3 can far-jump to conforming
; 		code in a ring 2 segment. The Privl field represent the highest
; 		privilege level that is allowed to execute the segment. For example,
; 		code in ring 0 cannot far-jump to a conforming code segment where Privl
; 		is 2, while code in ring 2 and 3 can. Note that the privilege level
; 		remains the same, ie. a far-jump from ring 3 to a segment with a Privl
; 		of 2 remains in ring 3 after the jump. 

; RW: Readable bit/Writable bit.
; 	For code segments: Readable bit. If clear (0), read access for this segment
; 	is not allowed. If set (1) read access is allowed. Write access is never
; 	allowed for code segments.
; 	For data segments: Writeable bit. If clear (0), write access for this
; 	segment is not allowed. If set (1) write access is allowed. Read access is
; 	always allowed for data segments. 

; A: Accessed bit. Best left clear (0), the CPU will set it when the segment is
; accessed. 

; Flags
; 3 | 2  | 1 | 0
; G | DB | L | Reserved

; G: Granularity flag, indicates the size the Limit value is scaled by.
; 	If clear (0), the Limit is in 1 Byte blocks (byte granularity).
; 	If set (1), the Limit is in 4 KiB blocks (page granularity).

; DB: Size flag.
; 	If clear (0), the descriptor defines a 16-bit protected mode segment.
; 	If set (1) it defines a 32-bit protected mode segment. A GDT can have both 16-bit and 32-bit selectors at once.

; L: Long-mode code flag.
; 	If set (1), the descriptor defines a 64-bit code segment. When set, Sz should always be clear.
; 	For any other type of segment (other code types or any data segment), it should be clear (0). 

; 0x08 .code 
; 0x10 .data
; 0x18 .user_data
; 0x20 .user_code
; 0x28 .tss
gdt64:
	dq 0 ; Zero entry
.code: equ $ - gdt64
	; Limit
	dw 0xffff
	; Base
	dw 0x0000
	; Base (mid)
	db 0x00
	; Access
	; present, dpl=0, descriptor, execute, readable
	db 10011010b
	; Flags & limit
	; Long mode, granularity
	; 0b1010_1111 == (1 << 5) | (1 << 7) | 0x0f
	db 10101111b
	; Base (high)
	db 0x00
.data: equ $ - gdt64
	; Limit
	dw 0xffff
	; Base
	dw 0x0000
	; Base (mid)
	db 0x00
	; Access
	; Present, dpl=0, descriptor, writable
	db 10010010b
	; Flags & limit
	; Long mode, granularity
	; 0b1010_1111 == (1 << 5) | (1 << 7) | 0x0f
	db 10101111b
	; Base (high)
	db 0x00
.user_data: equ $ - gdt64
	; Limit
	dw 0xffff
	; Base
	dw 0x0000
	; Base (mid)
	db 0x00
	; Access
	; Present, dpl=3, writeable
	db 0xf2
	; Flags & limit
	; Long mode, granularity
	db 10101111b
	; Base (high)
	db 0x00
.user_code: equ $ - gdt64
	; Limit
	dw 0xffff
	; Base
	dw 0x0000
	; Base (mid)
	db 0x00
	; Access
	; Present, dpl=3, execute, readable
	db 0xfa
	; Flags & limit
	; Long mode, granularity
	db 10101111b
	; Base (high)
	db 0x00
.tss: equ $ - gdt64
	; Limit
	dw 0x67 ; Sizeof tss64
	; Base
	dw (tss64 - $$ + MULTIBOOT_ORG + 0x30) & 0xffff
	; Base (mid)
	db ((tss64 - $$ + MULTIBOOT_ORG + 0x30) >> 16) & 0xff
	; Access
	; Present | TSS (0x9)
	;
	; "In most systems, the DPLs of TSS descriptors are set to values less than 3,
	; so that only privileged software can perform task switching. However, in
	; multitasking applications, DPLs for some TSS descriptors may be set to 3 to
	; allow task switching at the application (or user) privilege level."
	;
	db 10001001b
	; Flags & limit
	db 00000000b
	; Base high
	db ((tss64 - $$ + MULTIBOOT_ORG + 0x30) >> 24) & 0xff
	; Base highest
	dd ((tss64 - $$ + MULTIBOOT_ORG + 0x30) >> 32)
	; Reserved
	dd 0
.pointer:
	dw $ - gdt64 - 1
	dq gdt64

tss64:
	           dd 0 ; Reserved
	.rsp0      dq STACK_TOP
	.rsp1      dq 0
	.rsp2      dq 0
	           dq 0 ; Reserved
	.ist1      dq 0
	.ist2      dq 0
	.ist3      dq 0
	.ist4      dq 0
	.ist5      dq 0
	.ist6      dq 0
	.ist7      dq 0
	           dq 0 ; Reserved
	           dw 0 ; Reserved
	.iopb      dw 0 ; no IOPB

extern set_up_page_tables
extern map_kernel_code_segment
extern map_kernel_data_segment
extern map_kernel_stack
extern map_frame_buffer
extern enable_paging
global init_long_mode
section .text
bits 32
init_long_mode:
	; TODO: remove hacky work-around for bug in objcopy.
	; NOTE: work-around for bug in objcopy when converting elf32 objects to
	; elf64 format. The call from multiboot_start to init_long_mode is converted
	; to call init_long_mode+4 after converting from elf32 to elf64. Thus we
	; insert four nops.
	times 4 nop

	; ebx contains the 32-bit physical address of the Multiboot2 information
	; structure provided by the boot loader.
	mov esp, temp_stack_top
	push ebx

	call set_up_page_tables
	call map_kernel_code_segment
	call map_kernel_data_segment
	call map_kernel_stack
	call map_frame_buffer

	call enable_paging
	lgdt [gdt64.pointer]

	; Load the TSS
	mov ax, gdt64.tss
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

	mov rbx, gdt64.data
	mov ds, rbx

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
