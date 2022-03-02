#!/bin/bash

set -e

cat /dev/null > /tmp/serial.log
cat /dev/null > /tmp/serial.raw
alacritty --class lapis-serial-log -e fish -c 'tail -f /tmp/serial.raw' &
alacritty --class lapis-serial-log -e tail -f /tmp/serial.log &
sleep 1

# -S     Do not start CPU at startup (you must type 'c' in the monitor).
alacritty -e \
	qemu-system-x86_64 \
	-S \
	-gdb tcp::1234 \
	-serial file:/tmp/serial.log \
	-serial file:/tmp/serial.raw \
	-drive media=disk,index=0,file=bin/fs.img,format=raw,if=ide \
	-cdrom bin/kernel.iso &

gdb \
	--quiet \
	-ex 'target remote localhost:1234' \
	-ex 'symbol-file bin/kernel.dbg' \
	-ex 'b kernel.c:64' \
	-ex 'continue'
