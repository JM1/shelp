#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# AppArmor configuration
#
# Ref.: https://wiki.debian.org/AppArmor/HowToUse

apt-get install apparmor apparmor-utils
apt-get install apparmor-profiles # Optional

# Only on Debian 9 (Stretch) and earlier, AppArmor is enabled by default as of Debian 10 (Buster)
# Ref.: https://wiki.debian.org/AppArmor/HowToUse
sudo perl -pi -e 's,GRUB_CMDLINE_LINUX="(.*)"$,GRUB_CMDLINE_LINUX="$1 apparmor=1 security=apparmor",' /etc/default/grub
update-grub
reboot
