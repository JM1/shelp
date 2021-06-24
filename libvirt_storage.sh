#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Move /var/lib/libvirt/ to another storage device
#
# NOTE: libvirt stores e.g. managed saves (virsh managedsave ...) to /var/lib/libvirt/ which therefore must be large 
#       enough to store RAM states of all VMs during host reboot phases.

systemctl stop libvirt-guests.service # TODO: Required?
systemctl stop libvirtd.service

################################################################################
#                                                                              #
# Option A: Remount a.k.a. bind storage device to /var/lib/libvirt/            #
#                                                                              #
DEST=/data/vmstore/
mv -vi /var/lib/libvirt/ "$DEST"
mkdir /var/lib/libvirt/

cat << EOF >> /etc/fstab

$DEST /var/lib/libvirt/ none defaults,bind 0 0

EOF

mount /var/lib/libvirt

#                                                                              #
################################################################################
#                                                                              #
# Option B: Mount storage device at /var/lib/libvirt/ directly                 #
#                                                                              #

DEV=/dev/raid60-vg/libvirt-lv

umount /mnt
mount "$DEV" /mnt/
mv -vi /var/lib/libvirt/* /mnt/
umount /mnt

vi /etc/fstab
# Add entry for file system $DEV at mount point /var/lib/libvirt/

mount /var/lib/libvirt/

#                                                                              #
################################################################################

systemctl start libvirtd.service
reboot
