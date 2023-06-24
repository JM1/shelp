#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# GDM3
#

###
# Disable automatic suspending after 20 mins of inactivity since GNOME 3.28)
#
# Ref.:
# https://gitlab.gnome.org/GNOME/gnome-control-center/issues/22#note_235526
# /var/lib/dpkg/info/gdm3.postinst
sudo -u Debian-gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo -u Debian-gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
sudo -u Debian-gdm dbus-launch gsettings list-recursively org.gnome.settings-daemon.plugins.power

###
# Enable Wayland sessions with NVIDIA GPUs
# Ref.:
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1008296
# https://wiki.archlinux.org/title/GDM#Wayland_and_the_proprietary_NVIDIA_driver

cat << 'EOF' >> /etc/udev/rules.d/61-gdm.rules
# 2023 Jakob Meng, <jakobmeng@web.de>
# Override existing udev rules to allow using Wayland sessions with NVIDIA GPUs in GDM3
# Ref.: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1008296
EOF

reboot

###
