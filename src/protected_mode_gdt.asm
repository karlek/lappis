; Vim: set ft=nasm

; GDT
gdt32:

; The mandatory null descriptor
.null:
	dq 0x0 ; `dd` means define quad word (i.e. 8 bytes)

 ; The code segment descriptor
.code:
	; Base=0x0, limit=0xfffff
	; 1st flags:  (present)1 (privilege)00 (descriptor type)1 -> 1001b
	; Type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
	; 2nd flags:  (granularity)1 (32 - bit default )1 (64 - bit seg )0 (AVL)0 -> 1100b
	dw 0xffff     ; Limit (bits 0-15)
	dw 0x0        ; Base  (bits 0-15)
	db 0x0        ; Base  (bits 16-23)
	db 10011010b  ; 1st flags, type flags
	db 11001111b  ; 2nd flags, Limit (bits 16-19)
	db 0x0        ; Base (bits 24-31)

; The data segment descriptor
.data:
	; Same as code segment except for the type flags:
	; Type flags: (code)0 (expand down)0 (writable)1 (accessed)0 -> 0010b
	dw 0xffff     ; Limit (bits 0-15)
	dw 0x0        ; Base  (bits 0-15)
	db 0x0        ; Base  (bits 16-23)
	db 10010010b  ; 1st flags, type flags
	db 11001111b  ; 2nd flags, Limit (bits 16-19)
	db 0x0        ; Base (bits 24-31)

.descriptor:
	; Size of our GDT, always less one of the true size
	dw $ - gdt32 - 1
	; Start address of our GDT
	dd gdt32

; Constants to get address of gdt
CODE_SEG equ gdt32.code - gdt32
DATA_SEG equ gdt32.data - gdt32
