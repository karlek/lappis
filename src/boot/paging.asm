global p4_table

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

	; Counter variable for each entry.
	mov ecx, 0

.map_p2_table:
	; Map ecx-th P2 entry to a huge page that starts at address 2MiB * ecx.
	mov eax, 0x200000          ; 2MiB

	; Note: `mul reg` stores the answer in *ax registers.
	mul ecx
	; Set flags `page size`, `present` and `writeable`.
	or eax, PRESENT|WRITABLE|PAGE_SIZE|USER_ACCESS
	mov [p2_table + ecx*8], eax
	cmp ecx, 0
	je .next
	; Make only the range 0x000000-0x200000 (2MiB) executable.
	mov dword [p2_table + ecx*8 + 4], 0 << 31
.next:
	inc ecx
	cmp ecx, NUM_PAGES
	jne .map_p2_table
	ret

map_kernel_stack:
.guard_page_start:
	mov eax, 0x200000
	mul ecx

	; Make it a `guard` page by removing WRITABLE.
	or eax, PRESENT|PAGE_SIZE|USER_ACCESS
	mov [p2_table + ecx*8], eax
	mov dword [p2_table + ecx*8 + 4], 1 << 31
	inc ecx

.loop:
	mov eax, 0x200000
	mul ecx

	or eax, PRESENT|WRITABLE|PAGE_SIZE|USER_ACCESS
	mov [p2_table + ecx*8], eax
	mov dword [p2_table + ecx*8 + 4], 1 << 31
	inc ecx

	cmp ecx, (NUM_PAGES+NUM_KERNEL_STACK_PAGES-1)
	jne .loop

.guard_page_end:
	mov eax, 0x200000
	mul ecx

	; Make it a `guard` page by removing WRITABLE.
	or eax, PRESENT|PAGE_SIZE|USER_ACCESS
	mov [p2_table + ecx*8], eax
	mov dword [p2_table + ecx*8 + 4], 1 << 31
	inc ecx

	ret

; Map the frame buffer.
; @param ecx: First free P2 entry.
map_frame_buffer:
	; Start mapping the frame buffer at address 0x8000000.
	mov eax, 0xfd000000
	; Set flags `page size`, `present` and `writeable`.
	or eax, PRESENT|WRITABLE|PAGE_SIZE|USER_ACCESS
	jmp .store

.loop:
	add eax, 0x200000
.store:
	mov [p2_table + ecx*8], eax
	mov dword [p2_table + ecx*8 + 4], 1 << 31

	inc ecx
	cmp ecx, (NUM_PAGES+NUM_KERNEL_STACK_PAGES+NUM_FRAME_BUFFER_PAGES)
	jne .loop

	ret
