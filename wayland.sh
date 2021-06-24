#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
########################################
#
# Wayland & apps requiring root rights, e.g. GParted
#
# Ref.:
#  https://ask.fedoraproject.org/en/question/102936/graphical-applications-cant-be-run-as-root-in-wayland-eg-gedit-beesu-gparted-nautilus/?answer=102967#post-id-102967
#  https://fedoraproject.org/wiki/Common_F25_bugs#wayland-root-apps
#  https://wayland.freedesktop.org/xserver.html#heading_toc_j_5

# As root:
apt-get --no-install-recommends install weston xwayland gparted

# As user:
cat << EOF >> ~/.config/weston.ini
[core]
modules=xwayland.so
EOF

weston
# Open terminal on top left corner
xhost +si:localuser:root
sudo gparted
xhost -si:localuser:root

# Quit weston with CTRL+ALT+BACKSPACE

########################################
