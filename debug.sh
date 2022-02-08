#!/bin/bash

set -e

# -S     Do not start CPU at startup (you must type 'c' in the monitor).
qemu-system-x86_64 \
	-S \
	-d int \
	-gdb tcp::1234 \
	-drive format=raw,file=bin/lapis.img &

gdb \
	--quiet \
	-ex 'target remote localhost:1234' \
	-ex 'symbol-file bin/kernel.dbg'
	# -ex 'break main' \
	# -ex 'continue'
