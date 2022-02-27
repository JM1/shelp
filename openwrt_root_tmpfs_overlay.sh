#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2022 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Set up a tmpfs overlay for the root filesystem on OpenWrt devices
#
# OpenWrt's jffs2 filesystem at /overlay provides a persistent and writeable filesystem on top of OpenWrt's readonly
# /rom filesystem [1]. On 4/32 devices (with 4MB flash and/or 32MB RAM) storage is severely limited [2], e.g. both
# packages luci and wpad cannot be installed at the same time. As a workaround you can build your own image [3] without
# luci but with wpad. To configure the router, you would then install LuCI temporarily to an tmpfs overlay for the root
# filesystem [4]. Once configuration with LuCI is done, the router is rebooted, removing the tmpfs overlay and LuCI.
#
# Ref.:
# [1] https://openwrt.org/docs/techref/filesystems
# [2] https://openwrt.org/supported_devices/openwrt_on_432_devices
# [3] https://openwrt.org/docs/guide-developer/toolchain/beginners-build-guide
# [4] https://forum.openwrt.org/t/how-can-i-setup-a-tmpfs-overlay-for-the-root-filesystem-to-go-on-top-of-the-existing-ubifs-overlay/121236

# login to OpenWrt router
ssh root@192.168.1.1

# Set up a tmpfs overlay for root filesystem on OpenWrt device

newroot=/pivot/new
oldroot=/pivot/old
tmproot=/pivot/tmp

# Create directories and setup a dedicated tmpfs for the overlay
mkdir -p "$newroot" "$oldroot" "$tmproot"
mount -t tmpfs tmpfs "$tmproot"
chmod 755 "$newroot" "$oldroot" "$tmproot"
mkdir -p "$tmproot/rom" "$tmproot/lower" "$tmproot/upper" "$tmproot/work"

# Set up read-only bind mounts of /rom and /overlay/upper into $tmproot
mount -o bind,ro /rom "$tmproot/rom"
mount -o bind,ro /overlay/upper "$tmproot/lower"

# Set up tmpfs overlay (tmpfs << /overlay/upper << /rom) at $newroot
mount -t overlay \
    -o "rw,noatime,lowerdir=$tmproot/lower:$tmproot/rom,upperdir=$tmproot/upper,workdir=$tmproot/work/" \
    "overlayfs:$tmproot" "$newroot"

# Bind-mount everything else into $newroot
cat /proc/mounts | awk '{print $2}' | grep -Fv "$newroot" | grep -Ev '^\/$' | while read -r mnt; do
    mkdir -p "$newroot$mnt";
    mount -o bind "$mnt" "$newroot$mnt"
done

# Make changes to /etc persistent
mount -o bind /etc/ /pivot/new/etc/

# Pivot root to $newroot
pivot_root "$newroot" "$newroot$oldroot"

# Run any commands on tmpfs overlay, e.g.
wifi up
/etc/init.d/wpad restart
/etc/init.d/network restart
opkg update
opkg install --force-space luci

# Reboot to remove tmpfs overlay
reboot
