section .bss

; Ensures page alignment
align 4096
temp_stack:
	resb 4096
temp_stack_top:

NUM_PAGES: equ 32
; 1 guard page, NUM_KERNEL_STACK_PAGES-2 stack pages, 1 guard page
NUM_KERNEL_STACK_PAGES: equ 4
; 4 bytes per pixel, 1280x1024 pixels = 5 MiB => three (3) pages of 2MiB.
NUM_FRAME_BUFFER_PAGES: equ 3

; Remember, skip the last guard page.
IST1_TOP: equ (2 << 20) * (NUM_PAGES+NUM_KERNEL_STACK_PAGES-2)
STACK_TOP: equ (2 << 20) * (NUM_PAGES+NUM_KERNEL_STACK_PAGES-1)

CR0_WRITE_PROTECT: equ 1 << 16

section .text
bits 32
