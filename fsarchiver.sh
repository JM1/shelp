#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Filesystem backups using fsarchiver
#

BACKUP_FILE=SDCARD_PART2-RPI_ROOT-BACKUP_$(date +%Y%m%d%H%M%S).fsa
DEVICE=/dev/disk/by-id/usb-Generic_STORAGE_DEVICE_000000082-0\:1-part2

fsarchiver probe detailed
fsarchiver savefs --verbose --compress=7 --jobs=4 --split=4500 --cryptpass=- "$BACKUP_FILE" "$DEVICE"
fsarchiver restfs --verbose "$BACKUP_FILE" id=0,dest="$DEVICE"
