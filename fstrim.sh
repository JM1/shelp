#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enable periodic fstrim for SSD disks
# NOTE: On Debian 9 (Stretch) fstrim.service and fstrim.service have to be copied
#       and installed manually from /usr/share/doc/util-linux/examples/!
# Ref.: /usr/share/doc/util-linux/README.Debian
systemctl enable fstrim.timer
