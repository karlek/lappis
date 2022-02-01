#!/bin/bash

set -e

# sudo systemctl start docker

make debug

# qemu-system-x86_64 -drive file=bin/lapis.img,format=raw
# docker build -t lapis .
# docker run -it lapis
