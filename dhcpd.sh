#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# DHCP server
#

################################################################################
#
# DHCP server using dnsmasq
#
# Ref.: man dnsmasq

apt install dnsmasq-base # full package dnsmasq is not required

# Kill all running instances if dnsmasq fails with error message
#  dnsmasq: failed to bind DHCP server socket: Address already in use
killall dnsmasq

# Run dnsmasq as a DHCP server in background, argument '--port=0' will disable dnsmasq's DNS function.
LANG=C dnsmasq --conf-file=/dev/null --port=0 --listen-address=10.0.0.150 --dhcp-range=10.0.254.1,10.0.254.50,255.255.0.0 --log-queries --log-dhcp

# Stop dnsmasq
killall dnsmasq

################################################################################
