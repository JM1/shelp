#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Monitor drives' SMART values
#

apt-get install smartmontools lm-sensors

cat << 'EOF' | patch -p0 -d /
--- /etc/smartd.conf.orig	2014-12-20 20:29:40.000000000 +0100
+++ /etc/smartd.conf	2016-06-23 17:00:03.105711070 +0200
@@ -18,7 +18,55 @@
 # Directives listed below, which will be applied to all devices that
 # are found.  Most users should comment out DEVICESCAN and explicitly
 # list the devices that they wish to monitor.
-DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner
+#DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner
+
+# 2016 Jakob Meng, <jakobmeng@web.de>
+#
+# Explanation:
+#  -d removable 
+#    > prevents errors in case a removable device like usb device has been removed
+#
+#  -n standby,q 
+#    > only test disks if they are not in standby or sleep mode (prevents spinning)
+#
+#  -H 
+#    > test health status of disks
+#
+#  -s S/../(1|15)/./15 
+#    > do a short test at every 1st and 15th day of a month at 15:00 o'clock
+#
+#  -m root
+#    > send warning mails to root
+#
+#  -M daily 
+#    > send mails every day in case of an error 
+#
+#  -f 
+#    > test SMART values for errors
+#
+#  -t 
+#    > enables '-p' and '-u' which causes smartd to tracks changes in all device attributes
+#
+#  -I 194 
+#    > Ignore temperatur changes (else syslog gets spammed)
+#
+#  -r 194 
+#    > Do not show normalized temperature (in range 1 - 255) but the real value (e.g. 22°C) 
+#
+#  -W 5,40,45 
+#    > Track temperature changes larger than 5°C, log temperatures > 40°C and send warnings > 45°C
+# 
+#  -R 5 
+#    > Track changes to raw value (non-normalized value / not in range 1-255) of Reallocated_Sector_Ct, 
+#    > which might be much bigger than 255, so small changes would not be noticed with normalized values.
+#
+#  -a 
+#    > like '-H -f -t -l selftest -l error -C 197 -U 198'
+#
+#  -M exec /usr/share/smartmontools/smartd-runner
+#    > run scripts in /etc/smartmontools/run.d/
+#
+DEVICESCAN -d removable -a -n standby,q -s S/../(1|15)/./15 -m root -M daily -I 194 -r 194 -W 5,40,45 -R 5 -M exec /usr/share/smartmontools/smartd-runner
 
 # Alternative setting to ignore temperature and power-on hours reports
 # in syslog.

EOF

systemctl restart smartd.service
# or
service smartd restart
