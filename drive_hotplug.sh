#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Safely remove (hotplug) a SAS or SATA disk from a running system
#
# Ref.:
# [1] https://unix.stackexchange.com/questions/43413/how-can-i-safely-remove-a-sata-disk-from-a-running-system/43450#43450
# [2] https://askubuntu.com/questions/298723/stop-switch-esata-hotpluggable-disk/298733#298733

# NOTE: First make sure that disk is not in use anymore, i.e. no partition is
#       mounted, no LVM2 volume is enabled and no LUKS devices are still open.

DISK=/dev/disk/by-id/YOURDISK

# NOTE: When drive has spun down aka it has entered low power consumption standby mode,
#       then disk will probably wake up when unregistering it from the kernel.

# Unregister the device from the kernel [1]
echo 1 >/sys/block/$(basename $(readlink $DISK))/device/delete

# Depending on the SAS/SATA controller/HBA, unregistering a disk will stop it as well, e.g. dmesg shows:
#  [1654793.956995] sd 0:0:0:0: [sda] Synchronizing SCSI cache
#  [1654793.972864] sd 0:0:0:0: [sda] Stopping disk
#  [1654794.505274] ata1.00: disabled
