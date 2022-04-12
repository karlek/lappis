FROM ubuntu:22.04

RUN apt update && apt upgrade -y
RUN apt install -y \
	mtools \
	gcc-11 \
	nasm \
	build-essential

RUN apt install -y \
	grub2-common \
	xorriso \
	qemu-system-x86

WORKDIR /src

COPY . .

RUN CC=gcc-11 make
CMD make run
