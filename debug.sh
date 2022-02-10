#!/bin/bash

set -e

# -S     Do not start CPU at startup (you must type 'c' in the monitor).
alacritty -e \
	qemu-system-x86_64 \
	-S \
	-gdb tcp::1234 \
	-cdrom bin/kernel.iso &

gdb \
	--quiet \
	-ex 'target remote localhost:1234' \
	-ex 'symbol-file bin/kernel.dbg' \
	-ex 'b main' \
	-ex 'continue'
