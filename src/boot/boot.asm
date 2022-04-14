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
	dd 1280
	dd 1024
	dd 32

align 8
; Also last tag.
framebuffer_tag_end:
	dw 0
	dw 0
	dd 8

multiboot_header_end:

extern main
global multiboot_start
section .text
bits 32
multiboot_start:
	; Todo: Since we nuke the stack, we can't return here.
	; So we jump to main from `init_long_mode`...
	;
	; Note: we will never return.
	call init_long_mode

; We have to do the switch to long mode in our dynamically loaded kernel code,
; since we have too many bytes of data/code to fit before the magic boot
; marker. The total size of the page table are 4096*4 = 16KB.
%include "src/boot/long_mode.asm"
%include "src/kernel/idt.asm"
%include "src/kernel/userland.asm"
