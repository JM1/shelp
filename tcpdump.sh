#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# tcpdump
#
# References:
#  https://www.rationallyparanoid.com/articles/tcpdump.html
#  http://nil.uniza.sk/linux-howto/using-tcpdump-diagnostic-dns-debian

# capture ICMP traffic (e.g. ping) on wifi device
tcpdump -n -i wlan0 "icmp"

# capture traffic from and to hosts 10.0.20.7 and 10.10.0.169 on device br-lan and show verbosely
tcpdump -n -vv -i br-lan "host 10.0.20.7 or host 10.10.0.169"

# capture DNS traffic over device eth0
tcpdump -i eth0 udp port 53

# live capture traffic via SSH, e.g. from FritzBox
cd /tmp/
mkfifo mycap
ssh root@host tcpdump -s 0 -n -w - -i dsl > mycap
# open /tmp/mycap as capture device in Wireshark
