#!/bin/bash

set -e

# sudo systemctl start docker

cat /dev/null > /tmp/serial.log
cat /dev/null > /tmp/serial.raw
alacritty --class lapis-serial-log -e tail -f /tmp/serial.log &
alacritty --class lapis-serial-log -e fish -c 'tail -f /tmp/serial.raw | xxd' &
sleep 1

qemu-system-x86_64 \
	-no-reboot \
	-no-shutdown \
	-d int \
	-serial file:/tmp/serial.log \
	-serial file:/tmp/serial.raw \
	-hda bin/fs.img \
	-cdrom bin/kernel.iso 

ps ax | grep alacritty | grep lapis-serial-log | awk '{print $1}' | xargs kill
