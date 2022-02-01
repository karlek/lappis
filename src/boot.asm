; vim: set ft=nasm

bits 16
org 0x7c00

; This is the memory offset to which we will load our kernel.
KERNEL_OFFSET equ 0x1000

start:
	; Set video mode to 80x25 text, 16 foreground colors, 8 background colors
	; https://web.archive.org/web/20121213064559/http://www.ousob.com/ng/asm/ng6fcde.php
	mov ah, 0x0 ; Set video mode. 
	mov al, 0x3 ; Video mode number.
	int 0x10
	
	; Load our kernel
	call .load_kernel

	; Note: we never return from this.
	call switch_to_protected_mode

	jmp $

.load_kernel:
	mov bx, MSG_LOAD_KERNEL
	call print

	mov bx, KERNEL_OFFSET
	mov dh, 47
	mov dl, [BOOT_DRIVE]
	call disk_read

	ret

%include "src/print.asm"
%include "src/print32.asm"
%include "src/disk_read.asm"
%include "src/gdt.asm"
%include "src/protected_mode.asm"

; Global variables
BOOT_DRIVE: db 0
MSG_LOAD_KERNEL: db "Loading kernel into memory.", 0

times 510-($-$$) db 0
dw 0xaa55
