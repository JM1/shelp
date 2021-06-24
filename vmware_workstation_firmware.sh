#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Extract VMWare BIOS/UEFI firmware
#
# References:
#  https://wiki.archlinux.org/index.php/VMware#Extracting_the_VMware_BIOS
#  http://pete.akeo.ie/2011/06/extracting-and-using-modified-vmware.html

objdump -h /usr/lib/vmware/bin/vmware-vmx | grep bios440
objdump -h /usr/lib/vmware/bin/vmware-vmx | grep efi64

objcopy /usr/lib/vmware/bin/vmware-vmx -O binary -j bios440 --set-section-flags bios440=a bios440.rom.Z
objcopy /usr/lib/vmware/bin/vmware-vmx -O binary -j efi64 --set-section-flags efi64=a efi64.rom.Z

perl -e 'use Compress::Zlib; my $v; read STDIN, $v, '$(stat -c%s "./bios440.rom.Z")'; $v = uncompress($v); print $v;' < bios440.rom.Z > bios440.rom
perl -e 'use Compress::Zlib; my $v; read STDIN, $v, '$(stat -c%s "./efi64.rom.Z")'; $v = uncompress($v); print $v;' < efi64.rom.Z > efi64.rom
