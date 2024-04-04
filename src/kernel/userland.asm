bits 64

global enter_userland
extern debug_buffer

syscall_landing_pad:
	; rax = syscall number
	cli

	cmp rax, 0
	jz .sys_print
	jnz .done

.sys_print:
	push rcx
	call debug_buffer
	pop rcx

.done:
	sti
	o64 sysret

yay_userland:
	mov rax, 1
	syscall
	; What to do here lol?
	jmp $

enter_userland:
	; rdi: ptr to userland.o
	; rsi: len of userland.o
	mov r12, rdi
	; mov r13, rsi

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
	mov rcx, rdi
	; r11: RFLAGS
	; 0x200000 | 0x200             | 0x2
	; cpuid    | enable interrupts | Always 1
	mov r11, 0x200202

	o64 sysret

	; mov rax, SYS_BECOME_KERNEL
	; syscall
