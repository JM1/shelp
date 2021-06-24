#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Start TTYs at tty2 instead of tty1 with systemd
#
cd /etc/systemd/system/getty.target.wants/
mv -i getty@tty1.service getty@tty2.service
