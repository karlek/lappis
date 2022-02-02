#!/bin/bash

set -e

# sudo systemctl start docker

qemu-system-x86_64 \
	-no-reboot \
	-serial file:/tmp/serial.log \
	-drive file=bin/lapis.img,index=0,if=floppy,driver=raw &

