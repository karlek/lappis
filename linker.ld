ENTRY(multiboot_start)

SECTIONS {
    . = 1M;

    .boot :
    {
        /* ensure that the multiboot header is at the beginning */
        *(.multiboot)
    }

    .text :
    {
        *(.text)
    }
}
