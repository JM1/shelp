#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# btrfs
#
# Why btrfs?
# - thanks to Data Checksums and RAID1 it allows defect detection and recovery
# - allows snapshots for e.g. backups
# - already packaged for Debian

# list all btrfs filesystems
findmnt --noheadings --types btrfs --uniq --output SOURCE --nofsroot | sort | uniq

# create
mkfs.btrfs -L MY_LABEL                   /dev/disk/by-id/DEVICE
mkfs.btrfs -L MY_LABEL -d raid1 -m raid1 /dev/disk/by-id/DEVICE /dev/disk/by-id/DEVICE2

# mount
btrfs filesystem show /dev/disk/by-id/DEVICE
mount /dev/disk/by-id/DEVICE /MOUNT_PATH

# rename (offline)
btrfs filesystem label <device> <newlabel>

# rename (online)
btrfs filesystem label <mountpoint> <newlabel>

# resize non-raid filesystems
btrfs filesystem resize max /MOUNT_PATH

# resize raid filesystems
btrfs filesystem show /MOUNT_PATH # identify no of devices
btrfs filesystem resize 1:max /MOUNT_PATH
btrfs filesystem resize 2:max /MOUNT_PATH
# ...

# scrub
btrfs scrub status /MOUNT_PATH
btrfs scrub start /MOUNT_PATH
btrfs scrub cancel /MOUNT_PATH

####################
# Convert non-raid filesystem to 2-device raid1
# Ref.: https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices#Conversion

mount /dev/sda1 /mnt
btrfs device add /dev/sdb1 /mnt

# Rebalance in foreground..
btrfs balance start -dconvert=raid1 -mconvert=raid1              /mnt
# ..or in background
btrfs balance start -dconvert=raid1 -mconvert=raid1 --background /mnt
btrfs balance status /mnt

btrfs filesystem show /mnt

####################
# Convert 2-device raid1 to single (non-raid) filesystem
# Ref.: https://superuser.com/a/1163580/629550

btrfs filesystem show /mnt
# Label: none  uuid: d386ac1a-3f06-4223-a2dd-513d5ad09daa
#         Total devices 2 FS bytes used 50.01MiB
#         devid    1 size 4.66GiB used 960.00MiB path /dev/vda2
#         devid    2 size 4.66GiB used 1.22GiB path /dev/vdb2

btrfs balance start --force -dconvert=single,devid=1 -mconvert=single,devid=1 --background /mnt
# 'devid=1' is the drive that will be kept

btrfs balance status /mnt

btrfs device delete /dev/vdb2 /mnt # remove 'devid=2'

####################
# Repair a btrfs raid filesystem after failed drives have been replaced and missing drives have been readded
#
# "If you lose a drive from a conventional RAID array, or an mdraid array, or a ZFS zpool, that array keeps on
#  trucking without needing any special flags to mount it. If you then add the failed drive back to the array,
#  your RAID manager will similarly automatically begin "resilvering" or "rebuilding" the array in order to
#  catch the temporarily missing drive up on any data it has missed out on.
#
#  That, unfortunately, is not the case with btrfs-native RAID."
#
# "In a normal RAID array, automounting with the missing disk included would make sense—after all, the array would
#  automatically and immediately begin rebuilding/resilvering the missing data onto the newly reconnected disk.
#  But that was not the case with btrfs nine years ago, and it's still not the case with btrfs today."
#
# "The command that we were supposed to run was btrfs balance—with both drives connected and a btrfs balance run,
#  it does correct the missing blocks, and we can now mount degraded on only the other disk"
# Ref.: https://arstechnica.com/gadgets/2021/09/examining-btrfs-linuxs-perpetually-half-finished-filesystem/2/

btrfs balance /mnt

####################
