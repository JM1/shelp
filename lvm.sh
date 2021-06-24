#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# lvm2
#

# Find physical volumes
pvscan
# NOTE: By default scan_lvs is 0 in /etc/lvm/lvm.conf so LVM LVs will not be scanned for layered PVs.
#
# "Configuration option devices/scan_lvs.
#  Scan LVM LVs for layered PVs, allowing LVs to be used as PVs.
#  When 1, LVM will detect PVs layered on LVs, and caution must be
#  taken to avoid a host accessing a layered VG that may not belong
#  to it, e.g. from a guest image. This generally requires excluding
#  the LVs with device filters. Also, when this setting is enabled,
#  every LVM command will scan every active LV on the system (unless
#  filtered), which can cause performance problems on systems with
#  many active LVs. When this setting is 0, LVM will not detect or
#  use PVs that exist on LVs, and will not allow a PV to be created on
#  an LV. The LVs are ignored using a built in device filter that
#  identifies and excludes LVs."
# Ref.: /etc/lvm/lvm.conf

# Scan LVM LVs for layered PVs
# NOTE: Set a filter in /etc/lvm/lvm.conf if any virtual machine uses LVM!
sed -i -e 's/scan_lvs .*/scan_lvs = 1/g' /etc/lvm/lvm.conf
update-initramfs -u -k all

# Limit the block devices that are used by LVM commands
vi /etc/lvm/lvm.conf
# To devices section add e.g.
#  filter = [ "a|^/dev/sd.*|", "a|^/dev/nvme.*|", "a|^/dev/loop.*|", "a|^/dev/libvirt-meta/.*|", "a|^/dev/libvirt-volumes-[0-9]*/(hdd|ssd)-raid[0-9]*|", "r|.*|" ]
#  global_filter = [ "a|^/dev/sd.*|", "a|^/dev/nvme.*|", "a|^/dev/loop.*|", "a|^/dev/libvirt-meta/.*|", "a|^/dev/libvirt-volumes-[0-9]*/(hdd|ssd)-raid[0-9]*|", "r|.*|" ]
update-initramfs -u -k all

# PV                                VG   Fmt  Attr PSize PFree 1st PE 
# /dev/disk/by-id/DEVICE      lvm2 ---  5,46t 5,46t   1,00m

# "Initialize physical volume(s) for use by LVM"
# Ref.: man pvcreate
#
# LVM ensures proper alignment at 1 MiB boundary since August 2010
# Ref.: https://www.thomas-krenn.com/en/wiki/Partition_Alignment
#pvcreate --dataalignmentoffset 7s /dev/disk/by-id/DEVICE
#pvcreate --metadatasize 250k /dev/disk/by-id/DEVICE
pvcreate /dev/disk/by-id/DEVICE /dev/disk/by-id/DEVICE2

# Analyse physical volume
pvdisplay
# pvs is a preferred alternative to pvdisplay which "shows the same information
# and more, using a more compact and configurable output format".
# Ref.: man pvdisplay
pvs

# View the list of all available fields
pvs -o help

# Print offset to the start of data on the underlying device
pvs -o+pe_start /dev/disk/by-id/DEVICE

# Print total amount of unallocated space in current units
pvs -o pv_free --noheadings /dev/disk/by-id/DEVICE

# Print total number of physical extents
pvs -o pv_pe_count --noheadings /dev/disk/by-id/DEVICE

# Print total number of allocated physical extents
pvs -o pv_pe_alloc_count --noheadings /dev/disk/by-id/DEVICE

# Create a volume group
vgcreate MY_VG_NAME /dev/disk/by-id/DEVICE /dev/disk/by-id/DEVICE2

# Show volume groups
vgdisplay
# vgs is a preferred alternative to vgdisplay that shows the same information
# and more, using a more compact and configurable output format.
# Ref.: man vgdisplay
vgs

# Create a logical volume
lvcreate --name MY_LV_NAME --size 100%FREE MY_VG_NAME

# Create a RAID logical volume
lvcreate --name MY_LV_NAME --size 100%FREE --type raid1 --mirrors 1 MY_VG_NAME

# Create a RAID logical volume with DM integrity
# Ref.: man lvmraid
#
# NOTE: Requires Debian 11 (Bullseye) or later
#
# NOTE: LVM's DM integrity layer has a severe impact on performance, e.g. 
#       read/write bandwidth on PCIe SSDs is easily decreased by ten and
#       latency increases by five.
#
# NOTE: lvcreate does not accept '--size 100%FREE' when creating RAID volumes.
#       Instead set an arbitrarily small size and extend the volume size step
#       by step with e.g.
#
#        $> lvextend VG/LV --size +10G
#
#       until no free physical extents are available anymore.
#
# NOTE: LVM's DM integrity support has limitations:
#
# "To work around some limitations, it is possible to remove integrity from the LV,
#  make the change, then add integrity again.  (Integrity metadata would need to
#  initialized when added again.)
#
#  LVM must be able to allocate the integrity metadata sub LV on a single PV that is
#  already in use by the associated RAID image. This can potentially cause a problem
#  during lvextend if the original PV holding the image and integrity metadata is full.
#  To work around this limitation, remove integrity, extend the LV, and add integrity 
#  again.
#
#  Additional RAID images can be added to raid1 LVs, but not to other raid levels.
#
#  A raid1 LV with integrity cannot be converted to linear (remove integrity to do this.)
#
#  RAID LVs with integrity cannot yet be used as sub LVs with other LV types.
#
#  The following are not yet permitted on RAID LVs with integrity: 
#   lvreduce, pvmove, snapshots, splitmirror, raid syncaction commands, raid rebuild."
#
# Ref.: man lvmraid
#
# NOTE: To activate Cache LVs or RAID1 LVs with DM integrity during system boot,
#       additional kernel modules have to be added to the initial ramdisk. If 
#       those modules are not present during boot, LVs will not be activated and
#       LVM's boot scripts indicate this in syslog with messages such as:
#
#         lvm[***]:   pvscan[***] VG *** skip autoactivation.
#
#       Ref.: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=989221
#
lvcreate --name MY_LV_NAME --size 10G --type raid1 --mirrors 1 --raidintegrity y MY_VG_NAME

# Enabling dm-cache caching for a logical volume
#
# NOTE: Adding a cache volume to a RAID logical volume with DM integrity is not (yet?) supported. For example:
#        $> lvconvert --type cache --cachevol MY_FAST_LV_NAME --cachemode writeback MY_VG_NAME/MY_LV_NAME
#          Command on LV MY_VG_NAME/MY_LV_NAME is invalid on LV with properties: lv_is_raid_with_integrity .
#          Command not permitted on LV MY_VG_NAME/MY_LV_NAME.
#
# Ref.: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/configuring_and_managing_logical_volumes/index#enabling-caching-to-improve-logical-volume-performance_configuring-and-managing-logical-volumes
#
# NOTE: To activate Cache LVs or RAID1 LVs with DM integrity during system boot,
#       additional kernel modules have to be added to the initial ramdisk. If 
#       those modules are not present during boot, LVs will not be activated and
#       LVM's boot scripts indicate this in syslog with messages such as:
#
#         lvm[***]:   pvscan[***] VG *** skip autoactivation.
#
#       Ref.: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=989221
lvcreate --size 100G --name MY_FAST_LV_NAME vg /dev/fast-pv
lvconvert --type cache --cachemode writeback --cachevol MY_FAST_LV_NAME MY_VG_NAME/MY_LV_NAME
# NOTE: "The default dm-cache cache mode is "writethrough". Writethrough ensures that any data written will be stored
#        both in the cache and on the origin LV. The loss of a device associated with the cache in this case would not
#        mean the loss of any data.
#
#        A second cache mode is "writeback". Writeback delays writing data blocks from the cache back to the origin LV.
#        This mode will increase performance, but the loss of a cache device can result in lost data.
#
#        With the --cachemode option, the cache mode can be set when caching is started, or changed on an LV that is
#        already cached."
#       Ref.: man lvmcache

# Remove but keep cache LV which is necessary e.g. when logical volume should be resized.
lvconvert --splitcache MY_VG_NAME/MY_LV_NAME

# Remove and delete cache LV which is necessary e.g. when logical volume should be resized.
lvconvert --uncache MY_VG_NAME/MY_LV_NAME

# Show logical volumes
lvdisplay --all
# lvs is a preferred alternative to lvdisplay which "shows the same information 
# and more, using a more compact and configurable output format".
# Ref.: man lvdisplay
lvs -a

# View list of all available fields
lvs -o help

# Show size of LV in current units
lvs -o lv_size --units b --noheadings VG/LV

# Enable volume group
vgchange -ay

# Disable volume group
vgchange -an

# Rename volume group
vgrename OLD_VG_NAME NEW_VG_NAME

# "Expand a PV after enlarging the partition."
# Ref.: man pvresize
pvresize /dev/disk/by-id/DEVICE

# Extend the size of an logical volume to full available capacity
# Ref.: https://serverfault.com/a/692428/373320
lvextend -l +100%FREE /dev/VGNAME/LVNAME

# Clear physical volume aka move physical extents to another physical volume
# Ref.: man pvmove
pvmove -v -d /dev/disk/by-id/DEVICE_TO_BE_CLEARED:1-1337 /dev/disk/by-id/TARGET_DEVICE
# /dev/disk/by-id/DEVICE_TO_BE_CLEARED is the physical volume which is cleared
# 1-1337 mark which physical extents should be moved
# /dev/disk/by-id/TARGET_DEVICE is physical volume to which extents are moved
#
# NOTE: Maybe use --alloc as well
