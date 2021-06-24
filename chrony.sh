#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Time synchronization with chrony
#

apt-get install chrony # possibly replacing an existing ntp daemon

# (Optional on Debian 8 (Jessie)) Do not act as NTP server, do not accept external NTP connections.
# NOTE: Since chrony 2.1.1-1 from Debian 9 (Stretch) 'chronyd' will strictly act as an NTP client by default.
cat << 'EOF' >> /etc/chrony/chrony.conf

# 2014 Jakob Meng, <jakobmeng@web.de>
# Listen for NTP packets on home-subnet only
# Listen for command packets on localhost only 
bindaddress _IP4_
bindaddress ::1
bindcmdaddress 127.0.0.1
bindcmdaddress ::1

EOF

vi /etc/chrony/chrony.conf # Replace _IP4_ with real ip address.

service chrony restart
