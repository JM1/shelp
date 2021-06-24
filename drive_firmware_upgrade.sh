#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# HDD firmware upgrades
#
# Ref.:
#  https://github.com/jandelgado/general/wiki/Firmware-update-of-Seagate-harddisk-using-Linux
#  https://sourceforge.net/p/hdparm/discussion/461704/thread/ab424a1e/

# Upgrade your 
# First download firmware upgrade file, e.g. Barracuda-ALL-GRCC4H.iso for Seagate HDD ST3000DM001 9YN166 from:
#  http://www.seagate.com/staticfiles/support/downloads/firmware/Barracuda-ALL-GRCC4H.iso
#  https://www.seagate.com/de/de/support/kb/barracuda-1tbdisk-platform-firmware-update-223651en/
7z x Barracuda-ALL-GRCC4H.iso
7z x GR-CC4H.ima
7z x LOD.zip

hdparm --yes-i-know-what-i-am-doing --please-destroy-my-drive --fwdownload GRCC4H6H.LOD /dev/disk/by-id/ata-ST3000DM001-9YN166_S1F0YGT0

reboot
