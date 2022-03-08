section .rodata
gdt64:
	dq 0 ; Zero entry
.code: equ $ - gdt64
	; [Descriptor type, present, executable, long mode flag]
	;
	; Descriptor type bit. If clear (0) the descriptor defines a system segment
	; (eg. a Task State Segment). If set (1) it defines a code or data segment.
	;
    ; Pr: Present bit. Allows an entry to refer to a valid segment. Must be set (1) for any valid segment.
	;
	; Ex: Executable bit. If clear (0) the descriptor defines a data segment.
	; If set (1) it defines a code segment which can be executed from.
	;
	; L: Long-mode code flag. If set (1), the descriptor defines a 64-bit code
	; segment. When set, Sz should always be clear. For any other type of
	; segment (other code types or any data segment), it should be clear (0).
	dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; Code segment
.pointer:
	dw $ - gdt64 - 1
	dq gdt64

section .text
bits 32
init_long_mode:
	mov esp, stack_top
	push ebx

	call set_up_page_tables
	call map_frame_buffer

	call enable_paging
	lgdt [gdt64.pointer]

	jmp gdt64.code:long_mode_start

bits 64
long_mode_start:
	; Clear the interrupt flag.
	cli

	mov rax, 0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov rbx, 0
	mov rcx, 0
	mov rdi, 0

	pop rdi
	call main

	; A hint that we have escaped the kernel.
	mov rax, 0xdeadbeef
	jmp $

%include "src/boot/paging.asm"
