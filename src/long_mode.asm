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

section .rodata
gdt64:
	dq 0 ; Zero entry
	; Descriptor type, present, executable, 64-bit flag
.code: equ $ - gdt64
	dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; Code segment
.pointer:
	dw $ - gdt64 - 1
	dq gdt64

section .text
bits 32
set_up_page_tables:
	; Map the first P4 entry to P3 table.
	mov eax, p3_table
	or eax, 0b11 ; Set flags `present` and `writeable`.
	mov [p4_table], eax

	; Map the first P3 entry to P2 table.
	mov eax, p2_table
	or eax, 0b11 ; Set flags `present` and `writeable`.
	mov [p3_table], eax

	; Counter variable for each entry.
	mov ecx, 0

.map_p2_table:
	; Map ecx-th P2 entry to a huge page that starts att address 2MiB * ecx.
	mov eax, 0x200000          ; 2MiB

	; Note: `mul reg` stores the answer in *ax registers.
	mul ecx                    ; Start address of ecx-th page.
	or eax, 0b10000011         ; Set flags `huge`, `present` and `writeable`.
	mov [p2_table + ecx*8], eax  ; Store the entry.

	inc ecx                    ; Increase counter.
	cmp ecx, 512               ; if counter == 52, the whole P2 table is mapped.
	jne .map_p2_table          ; else map the next entry.

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
	call enable_paging
	lgdt [gdt64.pointer]
	jmp gdt64.code:long_mode_start

bits 64
long_mode_start:
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

	call main
	jmp $
	; mov rax, 0x2f592f412f4b2f4f
	; mov qword [0xb8000], rax
	; jmp $
