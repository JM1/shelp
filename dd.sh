#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#

########################################
#
# Clone disk to file image
#
dd if=/dev/disk/by-id/usb-Generic_STORAGE_DEVICE_000000082-0\:1  bs=4096 | pbzip2 -c | dd of=SanDiskExtreme32GB_RPi_SDCARD_Vollsicherung_20151224.dd.img.bzip2 bs=4096
md5sum SanDiskExtreme32GB_RPi_SDCARD_Vollsicherung_20151224.dd.img.bzip2 > SanDiskExtreme32GB_RPi_SDCARD_Vollsicherung_20151224.dd.img.bzip2.md5

########################################
#
# Backup whole system and mount image
#

dd if=/dev/sda of=win_hd.dd bs=4096 conv=noerror, sync
# bs=4096 => Schneller, weil Speichern eines ganzen Clusters effizienter als die eines einzelnen Sektors
# conv-Parameter => Stellt sicher, dass Kopiervorgang bei defekten Sektoren nicht abbricht

fdisk -lu win_hd.dd
disktype win_hd.dd

losetup -o $((63*512) /dev/loop0 win_hd.dd
# 63 oder 2047 => Partition beginnt üblicherweise bei 63, Vista jedoch als Ausnahme bei 2047
mount -o ro,noatime,noexec /dev/loop0 /mnt

########################################
# Geschwindigkeit der Platten mit dd messen
# Ref.: http://it.toolbox.com/blogs/database-soup/testing-disk-speed-the-dd-test-31069
time sh -c "dd if=/dev/zero of=ddfile bs=4k count=400000 && sync"

########################################
