bits 64
extern main
kernel_start:
	call main
	jmp $
