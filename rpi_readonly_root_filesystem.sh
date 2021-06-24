#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Read-only root filesystem with writeable overlay using tmpfs and a generic (kernel-independent) initrd
#
# NOTE: Only works on systems that are able to boot without an initrd like a default Raspbian installation.
#       The reason is that we replace the initrd with a generic meaning kernel-independent initrd that does not include 
#       any kernel modules but instead loads them from the root filesystem. But for that the kernel must already have 
#       those modules compiled in that are required to access the filesystem, e.g. the ext4 filesystem module.
#
# NOTE: Only works for Raspberry Pi, not a x86 computers! This is because we use a busybox binary that was compiled 
#       for the Raspberry Pi!
#
# ATTENTION: On Raspbian Jessie a system like described below will boot but because of a mysterious bug(?) 
#            there is no space left on the overlay filesystem.

apt-get install git
TMPDIR=$(mktemp -d)
cd "${TMPDIR}"
mkdir initramfs
cd initramfs

git clone --depth 1 https://github.com/raspberrypi/target_fs.git ./

rm init

cat << EOF > init
#!/bin/busybox sh

set -x

# Mount the /proc and /sys filesystems.
mount -t proc none /proc
mount -t sysfs none /sys
 
# Populate /dev
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s

# Load required kernel modules
ROOTFS=\$(grep -o -E '\broot=\S+' /proc/cmdline | cut -c 6-)
ROOTFSTYPE=\$(grep -o -E '\brootfstype=\S+' /proc/cmdline | cut -c 12-)

ROOTOPS="-o ro"
if [ "x\${ROOTFSTYPE}" != "x" ]; then
    ROOTOPS="\${ROOTOPS} -t \${ROOTFSTYPE}"
fi

mount \${ROOTOPS} \${ROOTFS} /mnt/root-ro
find /mnt/root-ro/lib/modules/\$(uname -r)/ -type f -name overlay.ko -exec busybox insmod '{}' \;

# Do overlayfs magic
mount -t tmpfs tmpfs /mnt/root-rw
cp -a /mnt/root-ro/mnt/persistent/. /mnt/root-rw
mkdir /mnt/root-rw/upper
mkdir /mnt/root-rw/work
mount -t overlay overlay -o lowerdir=/mnt/root-ro,upperdir=/mnt/root-rw/upper,workdir=/mnt/root-rw/work /rootfs

# Move mounts
mount --move /mnt/root-ro /rootfs/mnt/root-ro
mount --move /mnt/root-rw /rootfs/mnt/root-rw

# Clean up.
umount /proc
umount /sys

exec switch_root /rootfs /sbin/init

echo "Failed to switch_root, dropping to a shell"
exec /bin/sh
EOF

# give init exec privileges
chmod +x init

mkdir -p mnt/root-ro
mkdir -p mnt/root-rw
mkdir rootfs

[ ! -d proc ] && mkdir proc
[ ! -d sys ] && mkdir sys
[ ! -d dev ] && mkdir dev
 
# you might also want to disable some mdev rules
echo > etc/mdev.conf

find . -name .git -a -type d -prune -o -print | cpio -o -H newc > ../initramfs.cpio
cd ..
gzip -c initramfs.cpio > initrd.img-generic


[ !-d /mnt/root-ro ] && mkdir -p /mnt/root-ro
[ !-d /mnt/root-rw ] && mkdir -p /mnt/root-rw
[ !-d /mnt/persistent/ ] && mkdir /mnt/persistent/

mount /boot
cat << EOF >> /boot/config.txt

initramfs initrd.img-generic
EOF
cp -ip initrd.img-generic /boot/
umount /boot

cd /
rm -rf "${TMPDIR}"

cat << EOF > /sbin/rpi-root-remount-ro
#!/bin/bash
 
echo -e "Remounting rootfs as read-only..."
mount -o remount,ro /mnt/root-ro
echo "DONE."
EOF
 
cat << EOF > /sbin/rpi-root-remount-rw
#!/bin/bash
 
echo -e "Remounting rootfs as read-write..."
mount -o remount,rw /mnt/root-ro
echo "DONE."
EOF

cat << EOF > /sbin/rpi-root-sync
#!/bin/bash
 
echo -e "Syncing rootfs...\n"
rsync -a -H -A -X --delete /mnt/root-rw/. /mnt/root-ro/mnt/persistent
echo "DONE."
EOF
 
chmod +x /sbin/rpi-root-remount-ro
chmod +x /sbin/rpi-root-remount-rw
chmod +x /sbin/rpi-root-sync
