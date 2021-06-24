#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Edit a disk image using losetup
#

# open disk image as loop device
FILE=2015-09-24-raspbian-jessie.img
DEV=$(losetup --show --partscan --find "${FILE}") # no --read-only flag here if you want gparted to do a fs check before copying the partition

# Analyse partitions
fdisk -l "$DEV"
sgdisk --print "$DEV"

# Edit now

# Close loop device
losetup -d "$DEV"

########################################
