#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup Bluetooth Keyboard with BlueZ 5.X
#
# References:
#  https://wiki.archlinux.org/index.php/bluetooth_keyboard

sudo -s
apt-get install bluetooth

cat << 'EOF' > /etc/btkbd.conf
# 2016 Jakob Meng, <jakobmeng@web.de>
#
# Config file for /etc/systemd/system/btkbd.service
# change when required (e.g. keyboard hardware changes, more hci devices are connected)
#
# Reference: https://wiki.archlinux.org/index.php/bluetooth_keyboard

# MAC address of your bluetooth keyboard
BTKBDMAC='00:07:61:06:E0:1E'

# hci device identifier of your bluetooth dongle, can be found with: hcitool dev
HCIDEVICE='hci0'

# Trigger udev until hci device shows up?
UDEV_QUIRK='yes'


EOF

cat << 'EOF' > /etc/systemd/system/btkbd.service
# 2016 Jakob Meng, <jakobmeng@web.de>
# Reference: https://wiki.archlinux.org/index.php/bluetooth_keyboard
[Unit]
Description=systemd Unit to automatically start a Bluetooth keyboard
Documentation=https://wiki.archlinux.org/index.php/Bluetooth_Keyboard
Requires=dbus-org.bluez.service
After=dbus-bluez.org.service
ConditionPathExists=/etc/btkbd.conf
ConditionPathExists=/usr/bin/hcitool
ConditionPathExists=/bin/hciconfig

[Service]
Type=oneshot
EnvironmentFile=/etc/btkbd.conf
ExecStart=/bin/sh -c "                                                         \
  if [ \"${HCIDEVICE}\" = '' ] || [ \"${BTKBDMAC}\" = '' ]; then               \
    echo 'Invalid configuration, please check your /etc/btkbd.conf';           \
    exit 1;                                                                    \
  fi;                                                                          \
  if [ \"${UDEV_QUIRK}\" = 'yes' ]; then                                       \
    echo \"Waiting for bluetooth device ${HCIDEVICE}...\";                     \
    i=0;                                                                       \
    while ! test -e \"/sys/class/bluetooth/${HCIDEVICE}\"; do                  \
      /bin/udevadm trigger --action=change;                                    \
      sleep 1;                                                                 \
      i=$(expr $i + 1);                                                        \
      [ $i -gt 30 ] && break || continue;                                      \
    done;                                                                      \
  fi;                                                                          \
  if ! test -e /sys/class/bluetooth/${HCIDEVICE}; then                         \
    echo \"Bluetooth device ${HCIDEVICE} not found.\";                         \
    exit 1;                                                                    \
  fi;                                                                          \
  /bin/hciconfig ${HCIDEVICE} up || exit 1;                                    \
  # ignore errors on connect, spurious problems with bt?                       \
  /usr/bin/hcitool cc ${BTKBDMAC} || exit 0;                                   \
  exit 0                                                                       \
"

[Install]
WantedBy=multi-user.target


EOF

systemctl daemon-reload
systemctl enable btkbd.service
systemctl start btkbd.service

udevadm trigger
rfkill unblock all
man systemd-rfkill.service

bluetoothctl -a
 # now inside bluetooth command line interpreter do:
 show
 power on
 agent KeyboardOnly
 default-agent
 pairable on
 remove 00:07:61:06:E0:1E
 scan on
 # Press button on back of your bluetooth keyboard
 # Wait until your keyboard shows up and write down its mac address, 
 # here it's 00:07:61:06:E0:1E
 pair 00:07:61:06:E0:1E
 # Wait until pin is shown, then enter this pin on your bluetooth keyboard 
 # and hit enter
 trust 00:07:61:06:E0:1E
 connect 00:07:61:06:E0:1E
 # Wait until connection is established
 discoverable off
 pairable off
 scan off
 quit

exit # the end
