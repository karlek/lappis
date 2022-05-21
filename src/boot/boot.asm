bits 16

MULTIBOOT_ORG: equ 0x100000

extern main

; We have to do the switch to long mode in our dynamically loaded kernel code,
; since we have too many bytes of data/code to fit before the magic boot
; marker. The total size of the page table are 4096*4 = 16KB.
%include "src/boot/long_mode.asm"
%include "src/kernel/idt.asm"
%include "src/kernel/userland.asm"
