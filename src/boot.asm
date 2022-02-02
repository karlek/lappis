; vim: set ft=nasm

bits 16
org 0x7c00

; This is the memory offset to which we will load our kernel.
KERNEL_OFFSET equ 0x1000

start:
	; Set video mode to 80x25 text, 16 foreground colors, 8 background colors
	; https://web.archive.org/web/20121213064559/http://www.ousob.com/ng/asm/ng6fcde.php

	; mov ah, 0x0 ; Set video mode. 
	; mov al, 0x3 ; Video mode number.
	; int 0x10

	; mov ax, 0x4f00 ; Get video mode. 
	; mov di, 0xA000
	; mov dword [di], 'VBE2'
	; mov al, 0x4f ; Video mode number.
	; int 0x10
	; mov ax, [0xA000+0xe]   ; VideoModePtr
	; mov ax, [0xA000+0x10]  ; Total memory blocks.

	; mov ds, ax ; ds = Total blocks 

	; mov ax, [0xa400+0x12] ; Width
	; mov bx, [0xa400+0x14] ; Height
	; mov cx, [0xa400+40] ; Framebuffer
	; jmp $

	; INT 0x10, AX=0x4F02, BX=mode, ES:DI=CRTCInfoBlock

	; xor ax, ax 
	; mov es, ax ; es = 0

	mov di, 0xa000+0x400  ; Middle of nowhere
	mov ax, 0x4f01        ; Get Mode Info
	mov cx, 0x011B        ; Mode number, 1280x1024, rgb, 24-bit (8:8:8)
	int 0x10

	mov bx, 0x411b ; Linear framebuffer version of 1280x1024, rgb, 24-bit (8:8:8)
	mov ax, 0x4f02 ; Set mode.
	int 0x10

	; In order for the firmware built into the system to optimize itself for
	; running in Long Mode, AMD recommends that the OS notify the BIOS about
	; the intended target environment that the OS will be running in: 32-bit
	; mode, 64-bit mode, or a mixture of both modes. This can be done by
	; calling the BIOS interrupt 15h from Real Mode with AX set to 0xEC00, and
	; BL set to 1 for 32-bit Protected Mode, 2 for 64-bit Long Mode, or 3 if
	; both modes will be used. 
	mov ax, 0xec00
	mov bx, 2            ; 64 bit
	int 0x15

	; Load our kernel
	call .load_kernel

	call switch_to_protected_mode
	; Todo: Ideally I'd like to switch to long mode before calling the kernel,
	; but the size constraint of the boot magic (0xaa55) at 512 bytes makes
	; this difficult.

	; We could load long mode starting code before, but I'm not sure if that's
	; "cleaner".

	; Jump to our kernel.
	; Note: we will never return from here.
	call KERNEL_OFFSET

.load_kernel:
	; mov bx, MSG_LOAD_KERNEL
	; call print

	mov bx, KERNEL_OFFSET
	mov dh, 47
	mov dl, [BOOT_DRIVE]
	call disk_read

	ret

%include "src/print.asm"
%include "src/disk_read.asm"
%include "src/protected_mode.asm"

; Global variables
BOOT_DRIVE: db 0
MSG_LOAD_KERNEL: db "Loading kernel into memory.", 0

times 510-($-$$) db 0
dw 0xaa55
