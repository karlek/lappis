bits 64

global enter_userland

; TODO: used to calculate userland stack. Ugly temporary hack.
extern USERLAND_ADDR
; Used to populate MSR_KERNEL_GS_BASE.
extern tss64_addr
; Array mapping syscall nr to func ptr.
extern syscall_table

PAGE_SIZE equ 0x200000

rsp0_offset equ 0x4
rsp2_offset equ 0x14

syscall_landing_pad:
	swapgs

	; save user rsp
	; tss64.rsp2
	mov gs:[rsp2_offset], rsp
	mov rsp, gs:[rsp0_offset]
	push rcx ; addr of instruction following syscall
	push r11 ; rflags
	push rbp
	push rbx
	push r12
	push r13
	push r14
	push r15

	; Setup fourth arg.
	; mov rcx, r10
	; rax = syscall number
	; rcx = the address of the instruction following SYSCALL
	; rdi = first arg
	; rsi = second arg
	; rdx = third arg
	; r10 = fourth arg (since rcx is clobbered)
	; r8  = fifth arg
	; r9  = sixth arg

	call syscall_table[rax*8]
	jmp .done

.done:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	pop r11
	pop rcx

	mov rsp, gs:[rsp2_offset]
	swapgs

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

	; MSR_FMASK: clear interrupt flag on syscall.
	xor rdx, rdx
	mov rax, 0x200
	mov rcx, 0xc0000084
	; Write to model specific register.
	wrmsr

	; MSR_LSTAR: specify syscall handler.
	; edx:eax = syscall_fptr
	mov rdx, syscall_landing_pad
	shr rdx, 32
	mov eax, syscall_landing_pad
	mov rcx, 0xc0000082
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

	; NOTE: This is one is super sneaky.
	; https://nfil.dev/kernel/rust/coding/rust-kernel-to-userspace-and-back/#setting-the-ia32_star-model-specific-register
	; TODO: hard-coded offsets of gdt selectors.
	mov edx, 0x130008
	wrmsr

	; MSR_KERNEL_GS_BASE
	mov rcx, 0xc0000102
	mov rax, qword [tss64_addr]
	mov rdx, rax
	shr rdx, 32
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

	mov esp, dword [USERLAND_ADDR]
	add rsp, PAGE_SIZE ; ignore guard page
	add rsp, 0x1000    ; make room for temp stack
	o64 sysret

	; mov rax, SYS_BECOME_KERNEL
	; syscall
