#!/bin/bash

set -ex

cat /dev/null > /tmp/serial.log
cat /dev/null > /tmp/serial.raw
kitty --class lappis-serial-raw -e tail -f /tmp/serial.raw &
kitty --class lappis-serial-log -e tail -f /tmp/serial.log &

kitty --class lappis-qemu \
	qemu-system-x86_64 \
	-cpu qemu64,+smep,+smap \
	-no-reboot \
	-no-shutdown \
	-S \
	-gdb tcp::1234 \
	-d int \
	-m size=4G \
	-monitor stdio \
	-serial file:/tmp/serial.log \
	-serial file:/tmp/serial.raw \
	-drive media=disk,index=0,file=bin/zipfs.img,format=raw,if=ide \
	-cdrom bin/kernel.iso &

sleep 1

kitty --class lappis-gdb -e gdb \
	--quiet \
	-command=debug.gdb

ps ax | grep kitty | grep lappis-serial-log | awk '{print $1}' | xargs kill
ps ax | grep kitty | grep lappis-serial-raw | awk '{print $1}' | xargs kill
ps ax | grep kitty | grep lappis-qemu       | awk '{print $1}' | xargs kill
