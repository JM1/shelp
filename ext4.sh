#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# ext4

# NOTE: 'acl' and 'user_xattr' are default mount options for ext3/4 filesystems
# Ref.: /etc/mke2fs.conf

# NOTE: ext4 enables write barriers by default, while ext3 does not
# Ref.: https://www.kernel.org/doc/Documentation/filesystems/ext4.txt

# create
mkfs.ext4 -T largefile -L MY_FS_LABEL -E stripe-width=32,resize=6000G /dev/disk/by-id/DEVICE
tune2fs -m 1 /dev/disk/by-id/DEVICE
tune2fs -i 4m -c -1 /dev/disk/by-id/DEVICE

# mount
dumpe2fs -h /dev/disk/by-id/DEVICE | grep UUID
mount                                                        /dev/disk/by-id/DEVICE /mnt/tmp1
mount -o errors=remount-ro                                   /dev/disk/by-id/DEVICE /mnt/tmp1
mount -o relatime,acl,user_xattr,barrier=1,errors=remount-ro /dev/disk/by-id/DEVICE /mnt/tmp1
umount /mnt/tmp1

# rename
tune2fs -L MY_NEW_LABEL /dev/disk/by-id/DEVICE

# set time the filesystem was last checked
tune2fs -T 20000101 /dev/disk/by-id/DEVICE
