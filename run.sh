#!/bin/bash

set -e

cat /dev/null > /tmp/serial.log
cat /dev/null > /tmp/serial.raw
alacritty --class lappis-serial-log -e fish -c 'tail -f /tmp/serial.raw' &
alacritty --class lappis-serial-log -e tail -f /tmp/serial.log &
sleep 1

qemu-system-x86_64 \
	-no-reboot \
	-no-shutdown \
	-d int \
	-m size=128M \
	-serial file:/tmp/serial.log \
	-serial file:/tmp/serial.raw \
	-drive media=disk,index=0,file=bin/zipfs.img,format=raw,if=ide \
	-drive media=disk,index=1,file=bin/fat32.img,format=raw,if=ide \
	-monitor stdio \
	-cdrom bin/kernel.iso

ps ax | grep alacritty | grep lappis-serial-log | awk '{print $1}' | xargs kill
