#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Suspend virtual machines on host shutdown
# and start them after host has booted again
#

cat << 'EOF' >> /etc/default/libvirt-guests

# 2016-2018 Jakob Meng, <jakobmeng@web.de>
ON_BOOT=start
ON_SHUTDOWN=suspend

EOF

# On Debian 9 (Stretch) and later
sed -i -e 's/#SYNC_TIME=1/SYNC_TIME=1/g' /etc/default/libvirt-guests

# (Optional) Increase shutdown timeout for libvirt domains to 1h
sed -i -e 's/#SHUTDOWN_TIMEOUT=300/SHUTDOWN_TIMEOUT=3600/g' /etc/default/libvirt-guests

systemctl restart libvirtd.service

# Disable systemd's timeout when suspending clients
# NOTE: Only required on Debian 8 (Jessie) and earlier
mkdir /etc/systemd/system/libvirt-guests.service.d/
cat << 'EOF' >> /etc/systemd/system/libvirt-guests.service.d/disable-timeout.conf
# 2016 Jakob Meng, <jakobmeng@web.de>
#
# Disable systemd's timeout for service unit to stop (defaults to 90 seconds)
# Ref.: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=803714
#
[Service]
TimeoutStopSec=0

EOF

systemctl daemon-reload

# (Optional) Verify timeout configuration
systemctl show libvirt-guests | grep Timeout
