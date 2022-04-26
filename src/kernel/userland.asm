bits 64

global enter_userland

USER_STACK_GS: equ 0x10

syscall_landing_pad:
	; rax = syscall number
	cli

	swapgs                      ; Swap GS base to kernel PCR
	mov gs:[USER_STACK_GS], rsp ; Save user stack

	mov rsp, [tss64.rsp0]         ; Switch to kernel stack

	; Handle syscall by calling the appropriate handler.
	; TODO
	; jmp $

	mov rsp, gs:[USER_STACK_GS] ; Restore user stack
	swapgs                      ; Switch to usermode gs

	sti
	sysret

yay_userland:
	push 1
	mov rcx, 0
	mov rax, 0xdeadcafebeefdead
	; syscall
	; div rcx
.loop:
	inc rcx
	jmp .loop

enter_userland:
	; SYSCALL function pointer
	; edx:eax = syscall_fptr
	mov rdx, syscall_landing_pad
	shr rdx, 32

	mov eax, syscall_landing_pad
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
	; eax: eip syscall EIP
	; edx: kernel_base << 16 | user_base
	mov rcx, 0xc0000081
	rdmsr

	mov edx, 0x130008
	wrmsr

	; Disable interrupts.
	; We enable interrupts when RFLAGS is restored.
	cli

	; rcx: userland entrypoint
	mov rcx, yay_userland
	; r11: RFLAGS
	; 0x200000 | 0x200             | 0x2
	; cpuid    | enable interrupts | Always 1
	mov r11, 0x200202

	o64 sysret
