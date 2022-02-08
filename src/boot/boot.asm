; vim: set ft=nasm

bits 16
; org 0x800
align 8


MULTIBOOT_PAGE_ALIGN: equ 0x1
MULTIBOOT_VIDEO_MODE: equ 0x4

MULTIBOOT_HEADER_TAG_END:           equ 0
MULTIBOOT_HEADER_TAG_OPTIONAL:      equ 1
MULTIBOOT_HEADER_TAG_ADDRESS:       equ 2
MULTIBOOT_HEADER_TAG_ENTRY_ADDRESS: equ 3
MULTIBOOT_HEADER_TAG_FRAMEBUFFER:   equ 5

MULTIBOOT_ARCHITECTURE_I386: equ 0

MB_MAGIC: equ 0xE85250D6 
MB_FLAGS: equ MULTIBOOT_ARCHITECTURE_I386

section .multiboot
multiboot_header:
	dd MB_MAGIC                               ; magic
	dd MB_FLAGS                               ; flags
	dd multiboot_header_end-multiboot_header  ; length
	dd -(MB_MAGIC+MB_FLAGS + (multiboot_header_end-multiboot_header))                   ; checksum

align 8
framebuffer_tag_start:
	dw 5
	dw 1
	dd 20
	dd 1024
	dd 768
	dd 32

align 8
; Also last tag.
framebuffer_tag_end:
	dw 0
	dw 0
	dd 8

multiboot_header_end:

global multiboot_start
section .text
bits 32
multiboot_start:
	jmp $

; .mb_header: dd          MB_MAGIC        ;magic
;             dd          MB_FLAGS        ;flags
;             dd          -(MB_MAGIC+MB_FLAGS)    ;checksum (0-magic-flags)
;             dd          .mb_header      ;our location (GRUB should load us here)
;             dd          0800h           ;the same... load start
;             dd          07C00h          ;load end
;             dd          0h              ;no bss
;             dd          multiboot_start ;entry point
; This is the memory offset to which we will load our kernel.
; KERNEL_OFFSET equ 0x1000

; start:
; 	; We need to get mode info in order to get the framebuffer address.
; 	mov ax, 0x4f01        ; Get Mode Info.
; 	mov cx, 0x011B        ; Mode number, 1280x1024, rgb, 24-bit (8:8:8)
; 	mov di, 0xa000+0x400  ; Location of mode info.
; 	int 0x10

; 	mov bx, 0x411b ; Linear framebuffer version of 1280x1024, rgb, 24-bit (8:8:8) (0x011b | 0x4000)
; 	mov ax, 0x4f02 ; Set mode.
; 	int 0x10

; 	; In order for the firmware built into the system to optimize itself for
; 	; running in Long Mode, AMD recommends that the OS notify the BIOS about
; 	; the intended target environment that the OS will be running in: 32-bit
; 	; mode, 64-bit mode, or a mixture of both modes. This can be done by
; 	; calling the BIOS interrupt 0x15 from Real Mode with AX set to 0xEC00, and
; 	; BL set to 1 for 32-bit Protected Mode, 2 for 64-bit Long Mode, or 3 if
; 	; both modes will be used. 
; 	mov ax, 0xec00
; 	mov bx, 2
; 	int 0x15

; 	; Load our kernel
; 	call .load_kernel

; 	call switch_to_protected_mode
; 	; Todo: Ideally I'd like to switch to long mode before calling the kernel,
; 	; but the size constraint of the boot magic (0xaa55) at 512 bytes makes
; 	; this difficult.

; 	; We could load long mode starting code before, but I'm not sure if that's
; 	; "cleaner".

; 	; Jump to our kernel.
; 	; Note: we will never return from here.
; 	call KERNEL_OFFSET

; .load_kernel:
; 	; mov bx, KERNEL_OFFSET
; 	; mov dh, 20
; 	; mov dl, [BOOT_DRIVE]

; 	; Store DX on stack so later we can recall how many sectors were request to
; 	; be read, even if it is altered in the meantime.
; 	; push dx

; 	mov ah, 0x41
; 	mov bx, 0x55aa
; 	mov dl, 0x80
; 	int 0x13

; 	; Check carry flag
; 	; The carry flag will be set if Extensions are not supported. 
; 	jc .disk_error

; 	; Offset	Size	Description
; 	;  0		1		size of packet (16 bytes)
; 	;  1		1		always 0
; 	;  2		2		number of sectors to transfer (max 127 on some BIOSes)
; 	;  4		4		transfer buffer (16 bit segment:16 bit offset) (see note #1)
; 	;  8		4		lower 32-bits of 48-bit starting LBA
; 	; 12		4		upper 16-bits of 48-bit starting LBA


; 	; To read a disk:

; 	;     Set the proper values in the disk address packet structure
; 	;     Set DS:SI -> Disk Address Packet in memory
; 	;     Set AH = 0x42
; 	;     Set DL = "drive number" -- typically 0x80 for the "C" drive
; 	;     Issue an INT 0x13. 

; 	; The carry flag will be set if there is any error during the transfer. AH
; 	; should be set to 0 on success.

; 	mov ah, 0x42
; 	mov dl, 0x80
; 	mov word [daps+2], 224
; 	mov si, daps
; 	int 0x13
; 	hlt 

; 	; Notes:

; 	; (1) The 16 bit segment value ends up at an offset of 6 from the beginning of
; 	; the structure (i.e., when declaring segment:offset as two separate 16-bit
; 	; fields, place the offset first and then follow with the segment because x86
; 	; is little-endian). 

; .disk_error:
; 	; mov bx, DISK_ERROR_MSG
; 	; call print
; 	jmp $

; ; Disk Address Packet Structure
; daps:
; 	db 16 ; Size
; 	db 0
; 	dw 56
; 	dd 8
; 	dd KERNEL_OFFSET

; ; Variables
; DISK_ERROR_MSG: db "Disk read error!", 0

; %include "src/boot/print.asm"
; ; %include "src/boot/disk_read.asm"
; %include "src/boot/protected_mode.asm"

; ; Global variables
; BOOT_DRIVE: db 0

; times 510-($-$$) db 0
; dw 0xaa55
