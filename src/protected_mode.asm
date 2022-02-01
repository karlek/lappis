bits 16
switch_to_protected_mode:
	cli
	lgdt [gdt32.descriptor]

	mov eax, cr0  ; To make the switch to protected mode, we set
	or eax, 0x1   ; the first bit of CR0, a control register.
	mov cr0, eax  ; Update the control register.

	jmp CODE_SEG:init_protected_mode

bits 32
init_protected_mode:
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov ebp, 0x90000
	mov esp, ebp

	call is_A20_on
	call is_A20_on
	jmp $

	ret

; Check A20 line
; Returns to caller if A20 gate is cleared.
; Continues to A20_on if A20 line is set.
; Written by Elad Ashkcenazi
is_A20_on:
	pushad

	mov edi, 0x112345  ; Odd megabyte address.
	mov esi, 0x012345  ; Even megabyte address.

	mov [esi], esi     ; Making sure that both addresses contain different values.
	mov [edi], edi     ; (if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi))

	cmpsd              ; Compare addresses to see if they're equivalent.
	popad
	jne A20_on         ; If not equivalent, A20 line is set.

	mov eax, 0xcafe
	jmp $
	ret                ; If equivalent, the A20 line is cleared.

A20_on:
	mov eax, 0xdead
	jmp $
	ret

%include "src/protected_mode_gdt.asm"
%include "src/print32.asm"
