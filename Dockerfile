FROM debian:trixie

# Needed for make:
# clang
# dosfstools
# grub-common
# grub-pc-bin (silently needed..)
# libisoburn-dev
# make
# mtools
# nasm
# xorriso
# zip
#
# Needed for zig:
# curl
# xz-utils
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  clang \
  curl \
  dosfstools \
  grub-common \
  grub-pc-bin \
  libisoburn-dev \
  make \
  mtools \
  nasm \
  xorriso \
  xz-utils \
  zip \
  lld \
  && rm -rf /var/lib/apt/lists/*

# Install zig
WORKDIR /zig

ADD --checksum=sha256:c7ae866b8a76a568e2d5cfd31fe89cdb629bdd161fdd5018b29a4a0a17045cad \
	https://ziglang.org/download/0.12.0/zig-linux-x86_64-0.12.0.tar.xz \
	/zig/zig-linux-x86_64-0.12.0.tar.xz
RUN tar Jxvf /zig/zig-linux-x86_64-0.12.0.tar.xz

ENV PATH="${PATH}:/zig/zig-linux-x86_64-0.12.0"

# Install rustup (as user)
RUN useradd -m -G users -s /bin/bash user
USER user

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
ENV PATH "$PATH:/home/user/.cargo/bin"

RUN rustup toolchain install nightly && \
	rustup default nightly && \
	rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

# Stay as user to make build artifacts owned by user.
WORKDIR /lappis

ENTRYPOINT ["make"]
