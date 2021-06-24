#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Debugging and Analysis of system behaviour
#

# Download MemTest86 Free (Version 8.3), flash to USB stick and boot it
# NOTE: Doing a complete RAM test might take hours!
# Ref.:
#  https://www.memtest86.com/download.htm
#  https://www.memtest86.com/tech_creating-linux-mac.html

# Enable Magic SysRq keys
# Whenever your system seems to hang, try those keys first before doing a hard reset.
#
# Ref.:
#  https://wiki.archlinux.org/index.php/Keyboard_shortcuts
#  https://en.wikipedia.org/wiki/Magic_SysRq_key
cat << 'EOF' > /etc/sysctl.d/10-magic-sysrq-keys.conf
# Enable all Magic SysRq keys
# On debian kernels, this value defaults to 438.
kernel.sysrq=1
EOF
reboot

# Forward journald to /dev/tty12 (see `journald.sh`)

# Analysis of system boot and login process using bootchartd
#
# To investigate the problem further, you could do the following:
# Install and configure bootchartd (apt-get install bootchartd bootchart) and
# prevent that the bootchartd is stopped when kdm is started (for example, by
# deleting the symlink / etc/rc2.d/S99bootchart => May not work for dependency
# based boot). Then restart your computer, log into Kde4 and waiting until the
# system was fully loaded. Then stop bootchartd by /etc/init.d/bootchart start
# (!). After that you can get an image of the boot process by starting
# bootchart (!= bootchartd). Of course further investigations are then needed
# to find the real cause. But it is a start...
