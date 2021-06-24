#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# systemd.mount
#

####################
#
# Prevent systemd from auto mounting devices, e.g. if you want to 
# securily assign a device exclusively to a virtual machine.
#
# Option --runtime disables mount unit until next reboot
#
# Ref.:
#  man systemd.mount
systemctl --type mount --all
systemctl mask --runtime windows.mount
umount /windows

####################
