section .bss

; Ensures page alignment
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack:
    resb 4096
stack_top:

NUM_PAGES: equ 256

PRESENT:   equ 0x1
WRITABLE:  equ 0x2
PAGE_SIZE: equ 0x80

section .text
bits 32
set_up_page_tables:
	; Map the first P4 entry to P3 table.
	mov eax, p3_table
	; Set flags `present` and `writeable`.
	or eax, PRESENT|WRITABLE
	mov [p4_table], eax

	; Map the first P3 entry to P2 table.
	mov eax, p2_table
	; Set flags `present` and `writeable`.
	or eax, PRESENT|WRITABLE
	mov [p3_table], eax

	; Counter variable for each entry.
	mov ecx, 0

.map_p2_table:
	; Map ecx-th P2 entry to a huge page that starts at address 2MiB * ecx.
	mov eax, 0x200000          ; 2MiB

	; Note: `mul reg` stores the answer in *ax registers.
	mul ecx
	; Set flags `page size`, `present` and `writeable`.
	or eax, PRESENT|WRITABLE|PAGE_SIZE
	mov [p2_table + ecx*8], eax

	inc ecx
	; We map 64 of the total 512 entries.
	cmp ecx, NUM_PAGES
	jne .map_p2_table
	ret

; Map the frame buffer.
; @param ecx: First free P2 entry.
map_frame_buffer:
	; Start mapping the frame buffer at address 0x8000000.
	mov eax, 0xfd000000
	; Set flags `page size`, `present` and `writeable`.
	or eax, PRESENT|WRITABLE|PAGE_SIZE
	jmp .store

.loop:
	add eax, 0x200000
.store:
	mov [p2_table + ecx*8], eax

	inc ecx
	; 4 bytes per pixel, 1280x1024 pixels = 5 MiB => three (3) pages of 2MiB.
	cmp ecx, (NUM_PAGES+3)
	jne .loop

	ret

enable_paging:
	; Load P4 to CR3 register. (CPU uses this to access the P4 table).
	mov eax, p4_table
	mov cr3, eax

	; Enable PAE-flag in CR4 register. (Physical Address Extension).
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; Set the long mode bit in the EFER MSR (Model Specific Register).
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	; Enable paging in the CR0 register.
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret
