#!/bin/bash

set -e

cat /dev/null > /tmp/serial.log
cat /dev/null > /tmp/serial.raw
kitty --class lappis-serial-raw -e fish -c 'tail -f /tmp/serial.raw' &
kitty --class lappis-serial-log -e tail -f /tmp/serial.log &
sleep 1

kitty --class qemu-starter \
	qemu-system-x86_64 \
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

kitty --class lappis-serial-raw -e gdb \
	--quiet \
	-command=debug.gdb

ps ax | grep kitty | grep lappis-serial-log | awk '{print $1}' | xargs kill
ps ax | grep kitty | grep lappis-serial-raw | awk '{print $1}' | xargs kill
ps ax | grep qemu-system-x86_64 | grep kernel\.iso | awk '{print $1}' | xargs kill
