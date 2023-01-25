#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Btrfs Maintenance
#

# NOTE: Also have a look at periodic btrfs filesystem monitoring in btrfs_stats.sh

# Enable periodic btrfs balance and btrfs scrub
# NOTE: Only available on Debian 10 (Buster) and later
# Ref.: /usr/share/doc/btrfsmaintenance/README.Debian
apt install btrfsmaintenance

cat << 'EOF' | patch -p0 -d /
--- /etc/default/btrfsmaintenance.orig  2019-08-27 08:04:32.838921055 +0200
+++ /etc/default/btrfsmaintenance       2019-08-27 08:04:53.502863986 +0200
@@ -40,7 +40,7 @@
 # (Colon separated paths)
 # The special word/mountpoint "auto" will evaluate all mounted btrfs
 # filesystems
-BTRFS_BALANCE_MOUNTPOINTS="/"
+BTRFS_BALANCE_MOUNTPOINTS="auto"
 
 ## Path:           System/File systems/btrfs
 ## Type:           string(none,daily,weekly,monthly)
@@ -81,7 +81,7 @@
 # (Colon separated paths)
 # The special word/mountpoint "auto" will evaluate all mounted btrfs
 # filesystems
-BTRFS_SCRUB_MOUNTPOINTS="/"
+BTRFS_SCRUB_MOUNTPOINTS="auto"
 
 ## Path:        System/File systems/btrfs
 ## Type:        string(none,weekly,monthly)
EOF
# or
vi /etc/default/btrfsmaintenance # Change BTRFS_BALANCE_MOUNTPOINTS and BTRFS_SCRUB_MOUNTPOINTS
# or
sed -i -e 's/^BTRFS_BALANCE_MOUNTPOINTS=\"\/\"/BTRFS_BALANCE_MOUNTPOINTS=\"auto\"/g' /etc/default/btrfsmaintenance
sed -i -e 's/^BTRFS_SCRUB_MOUNTPOINTS=\"\/\"/BTRFS_SCRUB_MOUNTPOINTS=\"auto\"/g' /etc/default/btrfsmaintenance


mkdir /etc/systemd/system/btrfs-balance.service.d
cat << 'EOF' >> /etc/systemd/system/btrfs-balance.service.d/override.conf
# 2019 Jakob Meng, <jakobmeng@web.de>
# Wait until btrfs balance job has finished
#
# Ref.: man systemd.service

[Service]
TimeoutStopSec=infinity

EOF

mkdir /etc/systemd/system/btrfs-scrub.service.d
cat << 'EOF' >> /etc/systemd/system/btrfs-scrub.service.d/override.conf
# 2019 Jakob Meng, <jakobmeng@web.de>
# Wait until btrfs scrub job has finished
#
# Ref.: man systemd.service

[Service]
TimeoutStopSec=infinity

EOF
systemctl daemon-reload

systemctl enable btrfs-balance.timer
systemctl enable btrfs-scrub.timer

# Only Debian 10 (Buster) and earlier
systemctl restart btrfsmaintenance-refresh.service
systemctl enable btrfsmaintenance-refresh.service
