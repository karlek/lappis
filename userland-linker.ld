ENTRY(yay_userland)

SECTIONS {
    . = 4M;

    .text :
    {
        *(.text)
    }
}
