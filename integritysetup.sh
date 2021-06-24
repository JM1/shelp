#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# integritysetup
#
# Ref.:
#  man integritysetup

integritysetup format /dev/disk/by-id/DEVICE
integritysetup open /dev/disk/by-id/DEVICE NAME_integrity
integritysetup close NAME_integrity

# Benchmark
# NOTE: Have a look on chapter about Benchmarking as well!

mkfs.ext4 /dev/mapper/NAME_integrity
mount /dev/mapper/NAME_integrity /mnt/tmp1/

mkfs.ext4 /dev/disk/by-id/DEVICE_WITHOUT_INTEGRITYSETUP_FOR_COMPARISON
mount /dev/disk/by-id/DEVICE_WITHOUT_INTEGRITYSETUP_FOR_COMPARISON /mnt/tmp2/

mkdir /mnt/tmp1/test && chown nobody /mnt/tmp1/test/
mkdir /mnt/tmp2/test && chown nobody /mnt/tmp2/test/

sudo -u nobody bonnie++ -b -d /mnt/tmp1/test/ -r 1000 # no write buffering
sudo -u nobody bonnie++ -b -d /mnt/tmp2/test/ -r 1000 # no write buffering
sudo -u nobody bonnie++    -d /mnt/tmp2/test/ -r 1000 # write buffering
sudo -u nobody bonnie++    -d /mnt/tmp1/test/ -r 1000 # write buffering

# use bon_csv2html and bon_csv2txt to convert CSV data to HTML and plain-ascii respectively
