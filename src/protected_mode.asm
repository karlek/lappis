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

	; Store some pixel data in the VESA linear framebuffer, this works perfectly
	; mov edi, [0xa400 + 40]
	; mov eax, 0xFFFF0000
	; mov ecx, 65536 / 4
	; rep stosd

	ret

%include "src/protected_mode_gdt.asm"
%include "src/print32.asm"
