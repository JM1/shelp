#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Stop GDM3 (since GNOME 3.28) to automatically suspends the system after 20 minutes of inactivity.
#
# Ref.:
#  https://gitlab.gnome.org/GNOME/gnome-control-center/issues/22#note_235526
#  /var/lib/dpkg/info/gdm3.postinst
sudo -u Debian-gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo -u Debian-gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
sudo -u Debian-gdm dbus-launch gsettings list-recursively org.gnome.settings-daemon.plugins.power

########################################
