#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#

####################
# Disable copy-on-write (CoW) on btrfs filesystems
# If underlying filesystem is e.g. btrfs then disable copy-on-write to improve performance.
#
# NOTE: Disabling copy-on-write will disable data checksums on BTRFS filesystems!
#
# NOTE: Disabling copy-on-write works only for newly created files!
#
# References:
#  https://wiki.archlinux.org/index.php/btrfs#Disabling_CoW

mkdir /dir
chattr +C /dir
cd /dir
touch file
lsattr file

####################
