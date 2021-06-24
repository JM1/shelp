#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Wipe drives and detect defect sensors
#

# Schedule S.M.A.R.T. selftests
smartctl -t short /dev/disk/by-id/DEVICE
smartctl -t long /dev/disk/by-id/DEVICE

# Write and read tests
# NOTE: Write tests are destructive!
# NOTE: Skip write tests on SSD because of limited lifetime
dd if=/dev/urandom of=/dev/disk/by-id/DEVICE bs=4096 ; \
dd if=/dev/zero of=/dev/disk/by-id/DEVICE bs=4096 ; \
dd if=/dev/disk/by-id/DEVICE of=/dev/null bs=4096

# Wipe/Purge drive
mdadm --zero-superblock /dev/disk/by-id/DEVICE
sgdisk --zap-all /dev/disk/by-id/DEVICE
# Skip zeroing if write tests have been executed
dd if=/dev/zero of=/dev/disk/by-id/DEVICE bs=4096

smartctl -a /dev/disk/by-id/DEVICE | less
