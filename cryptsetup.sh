#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# cryptsetup
#
# Ref.:
# /usr/share/doc/cryptsetup/README.gnupg
# /usr/share/doc/cryptsetup-run/README.gnupg
# https://wiki.archlinux.org/title/Dm-crypt/Device_encryption

if [ -e /keys/KEYFILE ]; then mv -i /keys/KEYFILE /keys/KEYFILE.old; fi
dd if=/dev/random of=/keys/KEYFILE bs=1 count=256
chmod u-w,g-r,o-r /keys/*

dd if=/dev/random bs=1 count=256 | gpg --no-options --no-random-seed-file \
 --no-default-keyring --keyring /dev/null --secret-keyring /dev/null \
 --trustdb-name /dev/null --symmetric --output /keys/KEYFILE.gpg

# Use gnupg passphrase to decrypt key required for luksAddKey
/lib/cryptsetup/scripts/decrypt_gnupg /keys/KEYFILE.gpg > /keys/KEYFILE 

# Print compiled-in defaults
cryptsetup --help

# Create paranoid LUKS2 container
cryptsetup --type luks2 --align-payload=8192 -v -c aes-xts-plain64 -s 512 -h sha512 luksFormat /dev/disk/by-id/DEVICE

# Create LUKS2 container with 4K sector size
#
# Possible drawbacks:
# "(1) Compatibility with old kernels and cryptsetup versions. The 4K encryption sector support is still fairly new,
#      after all.
#  (2) It's not guaranteed safe on disks with 512-byte sectors, as it can break atomicity guarantees that might be
#      assumed by software. I don't believe this is a problem on modern disks or flash storage, nor on ext4 or f2fs.
#      But the cryptsetup default needs to be more conservative."
# Ref.: https://wiki.archlinux.org/title/Dm-crypt/Device_encryption
cryptsetup luksFormat --sector-size 4096 /dev/disk/by-id/DEVICE

cryptsetup luksAddKey /dev/disk/by-id/DEVICE # passphrase
cryptsetup luksAddKey /dev/disk/by-id/DEVICE /keys/KEYFILE

cryptsetup luksOpen /dev/disk/by-id/DEVICE NAME_crypt # passphrase
cryptsetup luksOpen /dev/disk/by-id/DEVICE NAME_crypt --key-file /keys/KEYFILE

cryptsetup luksDump /dev/disk/by-id/DEVICE | grep UUID

# Resize to size of the underlying block device
cryptsetup resize NAME_crypt

# Erase all keyslots and make the LUKS container permanently inaccessible.
cryptsetup luksErase /dev/disk/by-id/DEVICE 

cryptsetup luksClose /dev/disk/by-id/DEVICE
cryptsetup luksClose NAME_crypt

cp -raiv /etc/crypttab /etc/crypttab.bak.$(date +%Y%m%d%H%M%S --reference /etc/crypttab)
vi /etc/crypttab
cat /etc/crypttab

# Follow cryptsetup_initrd_unlock.sh to unlock root filesystem with SSH login to initrd/initramfs

####################
#
# Rename cryptsetup (LUKS) device
#
sed -i 's/OLD_crypt/NEW_crypt/g' /etc/crypttab
dmsetup rename OLD_crypt NEW_crypt
# Update references from OLD_crypt to NEW_crypt
vi /etc/mdadm/mdadm.conf
vi /etc/crypttab
vi /etc/fstab
vi /etc/default/grub

update-initramfs -k all -u
update-grub
reboot

####################
