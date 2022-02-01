bits 64
extern main
kernel_start:
	call init_long_mode
	jmp $

; We have to do the switch to long mode in our dynamically loaded kernel code,
; since we have too many bytes of data/code to fit before the magic boot
; marker. The total size of the page table are 4096*4 = 16KB.
%include "src/long_mode.asm"
