FROM archlinux:base-20220123.0.45312

RUN pacman -Syu --noconfirm qemu

CMD ["qemu-system-x86_64", "-display", "curses"]
