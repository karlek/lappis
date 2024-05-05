
<div align="center">

<img src="logo/transparent-logo.png" width="400" alt="Lappis">

[![Compile][compile-badge]][compile]

A toy 64-bit operating system.<br>


[Features](#features) •
[Getting started](#getting-started)

</div>

## Features

* Featuring a unique file system: **zipfs**. Your whole file system is mapped in
  memory from a single zip archive :kissing_smiling_eyes::ok_hand:
* Re-live your glory days with keyboard and mouse drivers from the PS2 era.
* Run RIP relative executables in userland with support for a whopping **1**
  system call(s)!
* The kernel is written in nasm, C, Rust and Zig for maximum spaghetti!
* Feel protected by SMEP and SMAP. Now you only have to worry about performance!
* NoTakeBack heap-allocator, don't worry about `free()`'s, you can't anyway!
* And of course: you can render a **mandelbrot**!

## Getting started

A little appetizer of what you'll experience before we begin.

<div align="center">
<img src="notes/screenshots/first-dog.png">
</div>

### Docker

```
# Build in docker.
$ docker build -t lappis-builder .

# We set --user to create build artifacts as our user.
$ docker run --rm -it --user "$(id -u):$(id -g)" -v $PWD:/lappis lappis-builder

# Run on host.
$ ./run.sh
```
### Dependencies

We need a few dependencies before we can compile and run lappis.

<details>
<summary>Arch</summary>

```
# Arch
# Build
pacman -S nasm mtools clang rustup zig libisoburn

# Dev
pacman -S bear

# Run
pacman -S qemu-full
```

</details>

<details>
<summary>Ubuntu</summary>

```
apt install -y nasm clang mtools

# Can't believe this is the recommended way to install rustup...
curl https://sh.rustup.rs -sSf | sh

snap install zig --classic --beta
```

</details>

### Configure Rust

We need to tell Rust to use the nightly channel and configure it so that we can
build freestanding targets.

```
rustup toolchain install nightly
rustup override set nightly
rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu
```

Now we are good to go!

### Running

Just run!
```
make run
```

## Roadmap

In the near future:

* Scheduling
* shell / pid 0 aka init

## Naming

The name original name was lapis, which means stone in latin since an operating
system acts as the foundation for what's to come. However, it fits even better
than we imagined since this OS is as dumb as a bag of rocks.

Later, the name affectionately became Lappis.


## Acknowledgments

* https://os.phil-opp.com/
* https://wiki.osdev.org/
* https://github.com/SerenityOS/serenity


[logo]: logo/transparent-logo.png
[compile-badge]: https://github.com/karlek/lappis/actions/workflows/build.yml/badge.svg?branch=main
[compile]: https://github.com/karlek/lappis/actions/workflows/build.yml
