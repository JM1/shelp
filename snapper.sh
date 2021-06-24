#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Filesystem snapshots with Snapper
#
# NOTE: Snapper supports btrfs subvolumes and thin-provisioned LVM volumes only!
#
# Ref.:
#  https://wiki.archlinux.org/index.php/Snapper
#  man snapper

apt install snapper

for MNT in "/" "/boot" "/home"; do
    if [ "$MNT" = "/" ]; then
        NAME=root
    else
        # Remove leading slash and replace other slashes with underscore
        NAME="$(echo "$MNT" | cut -d "/" -f 2- | sed -e 's/\//_/g')"
    fi

    snapper -c $NAME create-config $MNT

    # disable hourly backups
    sed -i -e "s/TIMELINE_CREATE=\"yes\"/TIMELINE_CREATE=\"no\"/g" /etc/snapper/configs/$NAME
done

snapper --config root list
snapper --config boot list
snapper --config home list

# Create snapshots on boot
mkdir /etc/systemd/system/snapper-boot.service.d
cat << 'EOF' > /etc/systemd/system/snapper-boot.service.d/override.conf
# 2019 Jakob Meng, <jakobmeng@web.de>
# Create snapshots on boot
#
# NOTE: Edit with
#       $> systemctl edit snapper-boot.service
#
# Ref.:
#  man systemd.service
#  /lib/systemd/system/snapper-boot.service

[Service]
# Snapshot of root is already created in /lib/systemd/system/snapper-boot.service
ExecStart=/usr/bin/snapper --config boot create --cleanup-algorithm number --description "boot"
ExecStart=/usr/bin/snapper --config home create --cleanup-algorithm number --description "boot"
EOF

systemctl daemon-reload
