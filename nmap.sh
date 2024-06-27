#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2024 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# nmap
#

###
# Test DHCP service configuration over the wire with nmap and tcpdump
# Ref.:
# https://serverfault.com/a/875791
# https://manpages.debian.org/unstable/nmap/nmap.1.en.html

sudo -s

apt install -y tcpdump nmap

# Identify network device which will be used for DHCP discover and offer packets
ip link

# Monitor network device, here enxf8bc1213e4c0, for DHCP traffic
tcpdump -i enxf8bc1213e4c0 -n -e -vvv 'port bootps or port bootpc'

# Run the following commands in parallel with tcpdump in another terminal

# Send DHCP discover packets
nmap --script broadcast-dhcp-discover

# Send DHCP discover packets for mac address f2:00:00:ff:03:01 on network device enxf8bc1213e4c0
nmap -e enxf8bc1213e4c0 --script broadcast-dhcp-discover --script-args mac=f2:00:00:ff:03:01

# For DHCPv6 use
nmap -6 --script broadcast-dhcp6-discover

###
