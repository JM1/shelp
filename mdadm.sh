#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# mdadm

# Analysis
mdadm --detail-platform --scan --verbose
mdadm --detail --scan --verbose
mdadm --examine --scan --verbose
# "--examine applies to devices which are components of an array, while
#  --detail applies to a whole array which is currently active."
# Ref.: man mdadm

# monitor resync
cat /proc/mdstat

# Create RAID1
mdadm --create /dev/md/DEVICE \
    --level=1 --raid-devices=2 --metadata=1.2 \
    /dev/disk/by-id/DEVICE1 \
    /dev/disk/by-id/DEVICE2

# Create RAID1 with missing device and add that missing device later
mdadm --create /dev/md/DEVICE \
    --level=1 --raid-devices=2 --metadata=1.2 \
    /dev/disk/by-id/DEVICE1 \
    missing

mdadm --manage /dev/md/DEVICE \
    --add /dev/disk/by-id/DEVICE2

# Deactivate array
mdadm --stop /dev/md/DEVICE

# Assemble array by uuid
mdadm --assemble /dev/md/DEVICE --uuid=UUID_FROM_EG_MDADM_DETAIL_SCAN_VERBOSE

# Grow linear RAID array
# See: https://bugzilla.redhat.com/show_bug.cgi?id=1122146#c5
mdadm /dev/md<X> -G -a /dev/sd<Y>

# Rename array
# Ref.: https://askubuntu.com/questions/63980/how-do-i-rename-an-mdadm-raid-array/64356#64356
mdadm --assemble /dev/md/DEVICE \
    --name=YOUR_NEW_NAME --update=name \
    --uuid=UUID_FROM_EG_MDADM_DETAIL_SCAN_VERBOSE

# Assemble readonly array by listing devices
mdadm --assemble --readonly /dev/md/DEVICE \
    /dev/disk/by-id/DEVICE1 \
    /dev/disk/by-id/DEVICE2

# "The word detached ... will cause any device that has been detached
#  from the system to be marked as failed. It can then be removed."
# Ref.: man mdadm
mdadm /dev/md/DEVICE --fail detached

# "detached ... causes any device which is no longer connected to 
#  the system (i.e an 'open' returns ENXIO) to be removed."
# Ref.: man mdadm
mdadm /dev/md/DEVICE --remove detached
