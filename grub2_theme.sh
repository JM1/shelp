#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# GRUB 2 themes
# Ref.: https://wiki.archlinux.org/index.php/GRUB/Tips_and_tricks#Theme

apt-get install grub-theme-starfield
mkdir /boot/grub/themes
cp -raiv /usr/share/grub/themes/starfield/ /boot/grub/themes/

cat << "EOF" >> /etc/default/grub
GRUB_THEME="/boot/grub/themes/starfield/theme.txt"
EOF

update-grub
# If configuring the theme was successful, the terminal will print:
#  Found theme: /usr/share/grub/themes/starfield/theme.txt
