#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# (s)gdisk
#

# Print partitions
sgdisk --print /dev/disk/by-id/DEVICE

# Replicate partition table and randomize its guids
sgdisk -R=/dev/disk/by-id/TARGET_DEVICE /dev/disk/by-id/SOURCE_DEVICE
sgdisk -G /dev/disk/by-id/TARGET_DEVICE

# Sort partition numbers, e.g. because Debian Installer assigns
# partition numbers in order of creation during install.
sgdisk --sort /dev/disk/by-id/DEVICE

# Wipe GPT and MBR data structures
sgdisk --zap-all /dev/disk/by-id/DEVICE

# Clear partition data, i.e. GPT header data, partition definitions and the protective MBR
sgdisk --clear /dev/disk/by-id/DEVICE

# Create new partition
sgdisk --set-alignment=4096 --new=0:0:0 /dev/disk/by-id/DEVICE
