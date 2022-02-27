#!/bin/bash

set -e

# -S     Do not start CPU at startup (you must type 'c' in the monitor).
alacritty -e \
	qemu-system-x86_64 \
	-S \
	-gdb tcp::1234 \
	-hda bin/foo.img \
	-cdrom bin/kernel.iso &

gdb \
	--quiet \
	-ex 'target remote localhost:1234' \
	-ex 'symbol-file bin/kernel.dbg' \
	-ex 'b read_zip' \
	-ex 'continue'
