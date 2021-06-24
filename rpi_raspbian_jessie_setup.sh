#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Fresh Raspbian Installation
#

# Download Raspbian from https://downloads.raspberrypi.org/raspbian_latest

FILE=2015-09-24-raspbian-jessie.zip
FILE_EXT=zip
CARD_DEV=/dev/disk/by-id/usb-Generic_STORAGE_DEVICE_000000082-0:1
TMP_DIR=/mnt/tmp1/

FILE="$(basename "${FILE}" .${FILE_EXT})" # Remove Extension
unzip ${FILE}.${FILE_EXT}

dd if="${FILE_EXT}.img" of="${CARD_DEV}" bs=4096

# GParted
sudo gparted ${CARD_DEV}

# Within GParted do:
# Move ext4 partition to end of sdcard but leave some dozens of megabytes left behind the partition
# Rename ext4 partition to RPI_OLD_ROOT on sdcard
# Resize boot partition on sdcard to 512MB, rename to RPI_BOOT on sdcard and add boot flag
# Create new ext4 partition called RPI_ROOT with size 8192MB between boot and ext4 partitions on sdcard
# Create new btrfs partition called RPI_DATA directy after RPI_ROOT filling up the entire space left on sdcard	
# Apply


rm "${FILE}.img"
sync

mount /dev/disk/by-label/RPI_BOOT "${TMP_DIR}"
vi ${MOUNT}/cmdline.txt
# Add
#  quiet systemd.show_status=1 logo.nologo
#
# If you are using a pitft device, then add
#  fbtft_device.name=pitft fbtft_device.rotate=90 fbtft_device.debug=2 fbtft_device.verbose=2 fbtft_device.fps=20 fbcon=map:10 
# If you want to use serial port remove
#  console=ttyAMA0,115200 console=tty1

umount "${TMP_DIR}"

# Boot Raspberry Pi with sdcard

# On Raspberry Pi do:
sudo -s
ifconfig eth0 192.168.1.254
exit

# On Host do:
ssh pi@192.168.1.254 # password is raspberry
sudo -s
umount /boot
#route add default gw 192.168.1.1
apt-get install debootstrap screen vim

screen -R
MOUNT=/mnt/tmp1
mkdir "${MOUNT}"
mount /dev/disk/by-label/RPI_ROOT "${MOUNT}"

debootstrap jessie "${MOUNT}" http://archive.raspbian.org/raspbian

mount -o bind /dev "${MOUNT}"/dev
mount -o bind /dev/pts "${MOUNT}"/dev/pts
chroot "${MOUNT}"
mount -t proc proc proc

cat << EOF > /etc/apt/sources.list
deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib non-free rpi
deb http://archive.raspberrypi.org/debian jessie main ui
# Uncomment lines below then 'apt-get update' to enable 'apt-get source'
#deb-src http://archive.raspbian.org/raspbian/ jessie main contrib non-free rpi
#deb-src http://archive.raspberrypi.org/debian jessie main ui
EOF

apt-key adv --keyserver keyserver.ubuntu.com --recv-key 82B129927FA3303E
apt-get update
apt-get install screen sudo vim p7zip-full curl debootstrap dosfstools ifplugd locales chrony strace tree ssh keyboard-configuration console-setup fake-hwclock dbus bash-completion btrfs-tools dphys-swapfile resolvconf htop psmisc libcap2-bin acl at time
dpkg-reconfigure locales # select your locales, e.g. de_DE.UTF8 and en_US.UTF8
dpkg-reconfigure tzdata # select your timezone
apt-get install raspi-config raspi-copies-and-fills raspi-gpio wiringpi # rpi-update

dpkg-reconfigure debconf # choose "Dialog" and "Low"

THEUSER=pi
adduser "${THEUSER}"
usermod --append --groups cdrom,sudo,plugdev "${THEUSER}"

update-alternatives --config editor

mkdir /data
ls -l /dev/disk/by-uuid/
vi /etc/fstab
#Example 1:
# proc            /proc           proc    defaults          0       0
# /dev/mmcblk0p1  /boot           vfat    defaults          0       2
# /dev/mmcblk0p3  /               ext4    defaults,noatime  0       1
# /dev/mmcblk0p4  /data           btrfs   defaults,noatime  0       2
# # a swapfile is not a swap partition, no line here
# #   use  dphys-swapfile swap[on|off]  for that
#
#Example 2:
# proc                                       /proc           proc    defaults                                            0       0
# UUID=74BD-74CF                             /boot           vfat    defaults,noauto                                     0       2
# UUID=eb1d20bf-4fa9-49a4-a07c-9f58b56d140c  /               ext4    defaults,relatime,acl,barrier=1,discard,user_xattr  0       1
# UUID=e5efa8bf-7ddf-4b95-a204-521f937d3682  /data           btrfs   relatime,defaults,discard                           0       2
# # a swapfile is not a swap partition, no line here
# #   use  dphys-swapfile swap[on|off]  for that

cat << EOF > /etc/dpkg/dpkg.cfg.d/wana-check-boot
# 2015 Jakob Meng, <jakobmeng@web.de>

#
# Verify that /boot is mounted before installing anything!
#
# quiet output:
#pre-invoke="mountpoint /boot 2>&1 >/dev/null"
# verbose output:
pre-invoke="mountpoint /boot"
EOF

cat << EOF >> /etc/apt/apt.conf
DPkg {
    // Auto mount/unmount /boot and /boot/efi
    Pre-Invoke { "if mountpoint /boot; then echo '/boot already mounted'; else mount /boot; fi"; };
    Post-Invoke { "sync ; test \${NO_APT_UNMOUNT:-no} = yes || if mountpoint /boot; then umount /boot; else echo '/boot already unmounted'; fi || true"; };
};
EOF

# Change to your needs
cat << EOF > /etc/network/interfaces.d/ethernet
auto eth0
iface eth0 inet static
    address 192.168.1.254
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 192.168.1.1
EOF

echo "127.0.0.1       $(hostname)" >> /etc/hosts

mv -i /etc/issue /etc/issue.orig

# Change to your needs
cat << EOF > /etc/issue
Welcome to \n

   host: \n.\o
  login: pi:raspberry
    sys: \s \m \r
release: \S{PRETTY_NAME}
   ipv4: \4{eth0} \4{eth0:1} \4{eth0:2}
  users: \U logged in
    tty: \l
   date: \d \t


EOF


vi /etc/default/ifplugd
# Change
#  INTERFACES=""
# To 
#  INTERFACES="eth0"

vi /etc/default/console-setup
# Change
#  FONTFACE="Fixed"
# To
#  #FONTFACE="Fixed"
#  FONTFACE="VGA"
# ATTENTION: Comment '#' added!

mkdir /etc/systemd/system/getty@tty1.service.d

cat << EOF > /etc/systemd/system/getty@tty1.service.d/noclear.conf
# Disable clearing of boot messages
# Reference: https://wiki.archlinux.org/index.php/Disable_clearing_of_boot_messages

[Service]
TTYVTDisallocate=no

EOF

cat << EOF >> /etc/modules
spi-bcm2708
snd-bcm2835
i2c-dev

# Uncomment the following three lines if you are using a pitft
# stmpe-ts
# fbtft
# fbtft_device

EOF

dphys-swapfile setup
dphys-swapfile swapon

mount /boot

vi ${MOUNT}/cmdline.txt
# Change
#  root=/dev/mmcblk0p2
# To
#  root=/dev/mmcblk0p3

cat << EOF >> /boot/config.txt
device_tree=

# ATTENTION: The following four lines overclock your pi!
arm_freq=900
core_freq=250
sdram_freq=450
over_voltage=2
EOF

umount /boot

umount /proc/
exit # chroot
umount "${MOUNT}/dev/pts"
umount "${MOUNT}/dev"
umount "${MOUNT}/sys"

cp -raiv /lib/modules/ "${MOUNT}/lib/"
umount "${MOUNT}"
exit # screen
init 0 # shutdown
# Power off and power on your Raspberry Pi

ssh-keygen -f "${HOME}/.ssh/known_hosts" -R 192.168.1.254
ssh-copy-id pi@192.168.1.254
scp -rp ~/.bashrc pi@192.168.1.254:/home/pi/
scp -rp .vim/ .vimrc pi@192.168.1.254:/home/pi/

ssh pi@192.168.1.254 # password is raspberry
sudo screen -R

cp -raiv /home/pi/.bashrc /root/
chown root.root /root/.bashrc
cp -raiv /home/pi/.vimrc /root/
chown root.root /root/.vimrc


timedatectl set-ntp true
timedatectl status

sed -i -e 's/#PasswordAuthentication yes/#PasswordAuthentication yes\nPasswordAuthentication no/g' /etc/ssh/sshd_config

service ssh restart

apt-get install raspberrypi-bootloader

# Change hostname
vi /etc/hostname
vi /etc/hosts
reboot


# If you want to access the original rasbian filesystem do
OLDROOT=/mnt/tmp1
mkdir "${OLDROOT}"
mount -o ro /dev/mmcblk0p2 "${OLDROOT}"
cd "${OLDROOT}"
# Current directory is the original rasbian root filesystem. When you're done, do
cd /
umount "${OLDROOT}"
