#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Force low power consumption standby mode aka spin down drives or
# force lowest power consumption sleep mode aka shut down drives completely
#
# Ref.:
# [1] man hdparm
# [2] https://www.htpcguides.com/spin-down-and-manage-hard-drive-power-on-raspberry-pi/

DISK=/dev/disk/by-id/YOURDISK

# "Check the current IDE power mode status, which will always be one of unknown (drive does not support this command), 
#  active/idle (normal operation), standby (low power mode, drive has spun down), or sleeping (lowest power mode, drive 
#  is completely shut down)." [1]
hdparm -C $DISK

# Force disk drive to enter low power consumption standby mode, usually causing it to spin down [1][2]
# NOTE: Subsequent disk accesses like "hdparm -C $DISK" will most likely wake up the drive again!
hdparm -y $DISK
#
# or
#
# "Force an IDE drive to immediately enter the lowest power consumption sleep mode, 
#  causing it to shut down completely. A hard or soft reset is required before the
#  drive can be accessed again (the Linux IDE driver will automatically handle 
#  issuing a reset if/when needed)." [1]
hdparm -Y $DISK
