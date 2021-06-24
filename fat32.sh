#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# fat32

mkfs.vfat -F 32 -n MY_LABEL /dev/disk/by-id/DEVICE
blkid /dev/disk/by-id/DEVICE

mount -o defaults,relatime /dev/disk/by-id/DEVICE /MOUNT_PATH
umount /MOUNT_PATH

# resize
#
# NOTE: fatresize is based on libparted which cannot
#       resize filesystems with sizes less than 256MB.
#       Doing so causes fatresize to crash with a segfault.
# Ref.:
#  manpage fatresize
#  https://bugzilla.gnome.org/show_bug.cgi?id=649324
fatresize -s SIZE /dev/disk/by-id/DEVICE

####################
# rename fat32 device (requires mlabel from mtools package)
mlabel -i /dev/disk/by-id/DEVICE -s ::
# Volume label is OLD_LABEL
mlabel -i /dev/disk/by-id/DEVICE ::NEW_LABEL
mlabel -i /dev/disk/by-id/DEVICE -s ::
# Volume label is NEW_LABEL (abbr=NEW_LABEL)
