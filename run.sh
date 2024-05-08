#!/bin/bash

set -ex

cat /dev/null > /tmp/serial.log
cat /dev/null > /tmp/serial.raw
alacritty --class lappis-serial-raw -e tail -f /tmp/serial.raw &
alacritty --class lappis-serial-log -e tail -f /tmp/serial.log &
sleep 1

# swaymsg '[app_id="lapis-serial-log"] move window to workspace 4'
kitty --class lappis-qemu \
	qemu-system-x86_64 \
		-cpu qemu64,+smep,+smap \
		-no-reboot \
		-no-shutdown \
		-d int \
		-m size=4G \
		-serial file:/tmp/serial.log \
		-serial file:/tmp/serial.raw \
		-drive media=disk,index=0,file=bin/zipfs.img,format=raw,if=ide \
		-monitor stdio \
		-cdrom bin/kernel.iso

ps ax | grep alacritty | grep lappis-serial-raw | awk '{print $1}' | xargs kill
ps ax | grep alacritty | grep lappis-serial-log | awk '{print $1}' | xargs kill
ps ax | grep kitty | grep lappis-qemu       | awk '{print $1}' | xargs kill
