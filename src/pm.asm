bits 16
switch_to_pm:
	cli
	lgdt [gdt_descriptor]

	mov eax, cr0  ; To make the switch to protected mode, we set
	or eax, 0x1   ; the first bit of CR0, a control register.
	mov cr0, eax  ; Update the control register.

	jmp CODE_SEG:init_pm

bits 32
init_pm:
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov ebp, 0x90000
	mov esp, ebp

	call KERNEL_OFFSET
