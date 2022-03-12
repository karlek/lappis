#!/bin/bash

set -e

cat /dev/null > /tmp/serial.log
cat /dev/null > /tmp/serial.raw
alacritty --class lapis-serial-log -e fish -c 'tail -f /tmp/serial.raw' &
alacritty --class lapis-serial-log -e tail -f /tmp/serial.log &
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
	-device e1000,netdev=n1,mac=52:54:00:12:34:56 \
	-cdrom bin/kernel.iso 

ps ax | grep alacritty | grep lapis-serial-log | awk '{print $1}' | xargs kill
