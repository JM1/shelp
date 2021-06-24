#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# GRUB 2 (PC/BIOS version) and GRUB 2 (amd64 UEFI signed by Debian)

# First install grub for UEFI systems
# Now install grub-pc but do not remove grub's uefi packages (!)

dpkg -l | grep grub | awk '{ print $2 }' | xargs echo
# Output should be something like
#  grub-common grub-efi-amd64-bin grub-efi-amd64-signed grub-pc grub-pc-bin grub-theme-starfield grub2-common

grub-install --target=i386-pc --recheck --debug /dev/sda
