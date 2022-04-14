bits 64

global enter_userland

syscall_landing_pad:
	mov rax, 0x1122334455667788
	jmp $

yay_userland:
	mov rcx, 0xdeadcafebeefdead
	jmp $

tss:
	dw 0
	dw 0x4800000

enter_userland:
	; SYSCALL function pointer
	; edx:eax = syscall_fptr
	mov rdx, syscall_landing_pad
	shr rdx, 32

	; mov edx, syscall_landing_pad >> 32
	mov eax, syscall_landing_pad
	; mov eax, syscall_landing_pad & 0xffffffff
	mov rcx, 0xc0000082
	; Write to model specific register.
	wrmsr

	; Enable SYSCALL.
	mov rcx, 0xc0000080
	rdmsr
	or eax, 0x1
	wrmsr

	;  0-31 SYSCALL EIP
	; 32-47 kernel segment base
	; 48-63   user segment base
	;
	; eax: eip syscall return address
	; edx: kernel_base << 16 | user_base
	mov rcx, 0xc0000081
	rdmsr
	mov edx, gdt64.code << 16 | gdt64.user_code
	wrmsr

	; Fifth 8-byte selector, symbolically OR-ed with 0 to set the RPL (requested
	; privilege level).
	; mov ax, (5 * 8) | 3
	; ltr ax

	; rcx: userland entrypoint
	; r11: RFLAGS
	mov rcx, yay_userland
	mov r11, 0x202

	o64 sysret
