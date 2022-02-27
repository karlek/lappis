#!/bin/bash

set -e

# sudo systemctl start docker

qemu-system-x86_64 \
	-no-reboot \
	-no-shutdown \
	-d int \
	-serial file:/tmp/serial.log \
	-hda bin/foo.img \
	-cdrom bin/kernel.iso 

	# -hda bin/lapis.img
	# -drive file=bin/lapis.img,index=0,media=disk

