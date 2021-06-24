#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Wake On Lan
#
# NOTE: In BIOS you have to set "LAN Boot Rom" and "Poweron on PCI Devices" / "PCI Devices Power On" to enabled!
# References:
#  http://azug.minpet.unibas.ch/~lukas/linux_recipes/wol.html
#  https://wiki.debian.org/WakeOnLan

# Minimal working example for Debian 6 (Squeeze) and later:
cat << 'EOF' >> /etc/network/interfaces
auto eth0
iface eth0 inet manual
    ethernet-wol g
EOF

# Minimal working example for Debian 5 (Lenny) and earlier:
cat << 'EOF' >> /etc/network/interfaces
auto eth0
iface eth0 inet manual
    pre-down /sbin/ethtool -s eth0 wol g
EOF
