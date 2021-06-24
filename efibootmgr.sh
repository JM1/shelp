#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# EFI Boot Manager
#
# Ref.:
#  https://wiki.debian.org/UEFI#efibootmgr_example_3_-_add_a_new_boot_entry
#  man efibootmgr

# Add Shim binary to EFI Boot Manager
efibootmgr --create --disk $(readlink -f /dev/disk/by-id/DEVICE) \
    --part PART_NUM_FOR_EXAMPLE_1 --loader \\EFI\\debian\\shimx64.efi --label debian \
    --write-signature --gpt # last two args are optional

# If this cmd failes with errors such as
#  efibootmgr: Could not set variable Boot0000: No space left on device
#  efibootmgr: Could not prepare boot variable: No space left on device
# then one might have to delete UEFI variables, e.g. as root run
rm /sys/fs/pstore/*
# and then try to run efibootmgr again.
# Ref.: https://donjajo.com/fix-grub-efibootmgr-not-set-variable-no-space-left-device/

efibootmgr --verbose
efibootmgr --bootnext 0
