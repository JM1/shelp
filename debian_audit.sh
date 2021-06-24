#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# System Audit
#

journalctl -xb # check for errors
reboot
journalctl -xb # check for errors again

# look for open ports
ss -tulpen
# or
netstat -tulpen # deprecated

# look for running daemons
systemctl list-units
systemctl list-unit-files | grep -v masked | grep -v static | grep -v disabled | grep -v indirect | grep -v generated

# look for unexplained files
cruft \
  --ignore /.bootbackup \
  --ignore /.snapshots \
  --ignore /opt \
  --ignore /home \
  --ignore /root \
  --ignore /var/www/nextcloud \
  --ignore /vm \
  --ignore /windows \
  --ignore /backups \
  --ignore /multimedia \
  -r /tmp/$(hostname)_cruft_report_$(date +%Y%m%d)

(
cd /
umask 337 # u=r,g=r,o=

# Disk analysis
OUT="/tmp/disk_analysis_$(hostname)_$(date '+%Y%m%d%H%M%S')"
(
  set -x
  lshw -class disk
  for dev in a b c d e f g h i j k l m n o p q r s t u v w x y z; do [ -e /dev/sd${dev} ] && { sgdisk --print /dev/sd${dev}; smartctl -A /dev/sd${dev}; } ;  done
  which mdadm >/dev/null && \
    mdadm --detail --scan --verbose
  which pvscan >/dev/null && \
    { pvscan; vgdisplay --verbose; lvdisplay --verbose; }
  ls -l /dev/disk/by-id/
  ls -l /dev/disk/by-uuid/
  which storcli64 >/dev/null && \
    storcli64 /call /eall /sall show
) >"${OUT}.txt" 2>&1
