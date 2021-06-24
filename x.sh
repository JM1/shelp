#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# X / X11 / X Version 11 / X Window System
#

################################################################################

# Disable DPMS and prevent screen from blanking
# Useful when watching movies or slideshows
xset -dpms; xset s off

# Disable display output immediately till next keypress or mouse movement
xset dpms force off

# Disable display output permanently
# Ref.: http://bbs.archlinux.org/viewtopic.php?pid=506200#p506200
vbetool dpms off
# This command turns off the monitor regardless of X is running or not. So, this is almost the answer I'm looking for.
# Now, let me explain that almost.
# There are two bad points to consider about this command:
# 1- Only super user is able to run it. (Actually, it's not a big deal. The computer is mine - I am a super user! big_smile )
# 2- The only way to turn on monitor back is with
vbetool dpms on
# and (this is the boring part) monitor is still off until you finish typing that and hit <enter>.

################################################################################
# Find keycode mappings for VMware Workstation

xev | sed -ne '/^KeyPress/,/^$/p' | while read line; do \
	KEYC1="$(echo $line | sed -rn 's/^.*keycode.(.*).\(.*/\1/p')"; \
	KEYC2="$(echo $line| sed -rn 's/^.*keysym\ 0x.*\,.(.*)\).*/\1/p')"; \
	if [ "$KEYC1" != "" ]; then \
		POSCODES1="$(grep  $KEYC2 "/usr/lib/vmware/xkeymap/de104")" ; \
		echo "xkeymap.keycode.$KEYC1 = 0x # $KEYC2"; \
		echo "Possible keycodes:"; \
		echo "$POSCODES1"| sort; \
	fi; \
done

################################################################################
# Keep environment when running with sudo, e.g. for GUI apps
sudo -E app

################################################################################
