section .bss

; Ensures page alignment
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack_bottom:
    resb 64
stack_top:

NUM_PAGES: equ 64

PRESENT:   equ 0x1
WRITABLE:  equ 0x2
PAGE_SIZE: equ 0x80

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
	mov eax, [0xa400+40]
	; Set flags `page size`, `present` and `writeable`.
	or eax, PRESENT|WRITABLE|PAGE_SIZE
	jmp .store

.loop:
	add eax, 0x200000
.store:
	mov [p2_table + ecx*8], eax

	inc ecx
	; 3 bytes per pixel, 1280x1024 pixels = 3.75 MiB => two pages.
	cmp ecx, (NUM_PAGES+2)
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

init_long_mode:
	mov esp, stack_top

	call set_up_page_tables
	call map_frame_buffer

	call enable_paging
	lgdt [gdt64.pointer]

	jmp gdt64.code:long_mode_start

bits 64
long_mode_start:
	cli ; Clear the interrupt flag.

    mov rax, 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

	mov rbx, 0
	mov rcx, 0
	mov rdi, 0

	call main
	jmp $
