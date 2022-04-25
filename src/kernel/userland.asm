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
	; eax: eip syscall EIP
	; edx: kernel_base << 16 | user_base
	mov rcx, 0xc0000081
	rdmsr

	; xor rax, rax
	mov edx, 0x130008
	; mov edx, (gdt64.user_code << 16) | gdt64.code
	wrmsr

	; rcx: userland entrypoint
	; r11: RFLAGS
	; Disable interrupts. We enable interrupts with RFLAGS in userland.
	; 0x2      | 0x200             | 0x200000
	; Always 1 | enable interrupts | cpuid
	cli

	; mov qword [tss64.rsp0], rsp
	; mov rsp, 0x300000

	push gdt64.user_data | 3 ; Stack segment, ss
	push 0x34000 ; rsp
	push 0x200 ; rflags
	push gdt64.user_code | 3 ; Code segment, cs
	push yay_userland ; rip
	iretq

; 	mov rcx, yay_userland
; 	mov r11, 0x200202

; 	o64 sysret
