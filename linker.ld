ENTRY(multiboot_start)

SECTIONS {
    . = 1M;

    .text : ALIGN(4K) {
        /* ensure that the multiboot header is at the beginning */
        KEEP(*(.multiboot))
        *(.text)
    }

    .rodata : ALIGN(4K) {
        *(.rodata)
    }

    .data : ALIGN(4K) {
        *(.data)
    }

    .bss : ALIGN(4K) {
        *(.bss)
    }
}
