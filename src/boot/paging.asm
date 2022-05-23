global p4_table
global p2_table

section .bss

; Ensures page alignment
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
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

PRESENT:     equ 0x1
WRITABLE:    equ 0x2
USER_ACCESS: equ 0x4
PAGE_SIZE:   equ 0x80

CR0_WRITE_PROTECT: equ 1 << 16
CR0_PAGING: equ 1 << 31

section .text
bits 32
set_up_page_tables:
	; Map the first P4 entry to P3 table.
	mov eax, p3_table
	; Set flags `present` and `writeable`.
	or eax, PRESENT|WRITABLE|USER_ACCESS
	mov [p4_table], eax

	; Map the first P3 entry to P2 table.
	mov eax, p2_table
	; Set flags `present` and `writeable`.
	or eax, PRESENT|WRITABLE|USER_ACCESS
	mov [p3_table], eax

	ret
