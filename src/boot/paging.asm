section .bss

; Ensures page alignment
align 4096
temp_stack:
	resb 4096
temp_stack_top:

CR0_WRITE_PROTECT: equ 1 << 16

section .text
bits 32
