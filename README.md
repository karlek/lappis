


<div align="center">

# Lappis

[![Compile][compile-badge]][compile]

</div>

A toy BIOS bootloader which kickstarts a toy 64-bit operating system.

The name lappis means stone in latin, since an operating system acts as the
foundation for what's to come. However, it fits even better than I imagined
since this OS is as dumb as a bag of rocks.

## Usage

```
make
```

## Dependencies

```
# Arch
pacman -S nasm qemu mtools xorriso
```

[compile-badge]: https://github.com/karlek/lappis/actions/workflows/build.yml/badge.svg?branch=main
[compile]: https://github.com/karlek/lappis/actions/workflows/build.yml
