#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Unlock root filesystem with SSH login to initrd/initramfs
#
# References on Debian 9 (Stretch) and later:
#  /usr/share/doc/cryptsetup/README.gnupg
#  /usr/share/doc/cryptsetup/README.initramfs.gz
#  /usr/share/doc/dropbear-initramfs/README.initramfs
#
# References on Debian 8 (Jessie):
#  /usr/share/doc/cryptsetup/README.remote.gz

# Debian 8 (Jessie)
apt-get install busybox dropbear
# Debian 9 (Stretch)
apt-get install busybox dropbear-initramfs

# Debian 8 (Jessie)
KEYFILE=/etc/initramfs-tools/root/.ssh/authorized_keys
# Debian 9 (Stretch)
KEYFILE=/etc/dropbear-initramfs/authorized_keys

cat << 'EOF' >> "$KEYFILE"
LIST YOUR SSH PUBLIC KEYS HERE
EOF

chmod g-rwx,o-rwx "$KEYFILE"

cat << EOF >> /etc/initramfs-tools/modules

# Needed in order to get ASIX AX88179/178A based USB 3.0/2.0 Gigabit Ethernet Devices working during boot
# Ref.: modinfo ax88179_178a
ax88179_178a
usbnet
mii
EOF

update-initramfs -u -k all

less /etc/network/interfaces

vi /etc/default/grub
# Add "ip=..." parameter to GRUB_CMDLINE_LINUX_DEFAULT, e.g.
#  GRUB_CMDLINE_LINUX_DEFAULT="ip=10.0.0.157:::255.255.0.0:Loutronik2LiDe:eth0:none"

update-grub

# NOTE: If you use the above ip and device e.g. in a bridge, then you might want
#       to flush the kernel-based ip prior renewing the network configuration:
vi /etc/network/interfaces
# iface eth0 inet # ...
#     pre-up ip addr flush dev eth0 # Remove kernel-based ip address set in /etc/default/grub


# (Optional) Prepare an encrypted keyfile
KEYNAME=md1
if [ ! -e /keys/ ]; then
    mkdir /keys/
    chown root.root /keys/
    chmod g-rwx,o-rwx /keys/
fi

if [ ! -e "$HOME/.gnupg/" ]; then
    mkdir "$HOME/.gnupg/"
    chown root.root "$HOME/.gnupg/"
    chmod g-rwx,o-rwx "$HOME/.gnupg/"
fi

# Debian 9 (Stretch)
# References:
#  https://github.com/keybase/keybase-issues/issues/2798
#  https://d.sb/2016/11/gpg-inappropriate-ioctl-for-device-errors
export GPG_TTY=$(tty)

# ascii key, e.g. suitable for unlocking via ssh
LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 256 > /keys/$KEYNAME.key
cat /keys/$KEYNAME.key | gpg --no-options --no-random-seed-file \
 --no-default-keyring --keyring /dev/null --secret-keyring /dev/null \
 --trustdb-name /dev/null --symmetric --output /keys/$KEYNAME.key.gpg

# binary key
dd if=/dev/random bs=1 count=256 | gpg --no-options --no-random-seed-file \
 --no-default-keyring --keyring /dev/null --secret-keyring /dev/null \
 --trustdb-name /dev/null --symmetric --output /keys/$KEYNAME.key.gpg
/lib/cryptsetup/scripts/decrypt_gnupg /keys/$KEYNAME.key.gpg > /keys/$KEYNAME.key

chmod u-w,g-r,o-r /keys/*
cryptsetup luksAddKey /dev/disk/by-id/... /keys/$KEYNAME.key

# copy /keys/$KEYNAME.key.gpg to client


# On client-side:
HOST=root@Loutronik2LiDe

cat << 'EOF' >> ~/.bash_aliases
# ssh for remote decryption of encrypted root filesystems via dropbear
alias ssh_initramfs='ssh -o UserKnownHostsFile=~/.ssh/known_hosts.initramfs'
EOF

# Unlock using a passphrase on Debian 8 (Jessie)
ssh_initramfs $HOST
/lib/cryptsetup/askpass "passphrase: " > /lib/cryptsetup/passfifo

# Unlock using a passphrase on Debian 9 (Stretch)
ssh_initramfs $HOST "cryptroot-unlock"

# Unlock using an encrypted keyfile
# Copy keyfile to client-side first
/lib/cryptsetup/scripts/decrypt_gnupg $KEYNAME.key.gpg | ssh_initramfs $HOST "cat > /lib/cryptsetup/passfifo"

exit # the end
