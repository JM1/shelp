#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Benchmark network throughput and/or bandwidth (Speed test) with iPerf3
#
# Ref.:
# https://iperf.fr/iperf-doc.php
# man iperf3

# Install iPerf3 on both endpoints, i.e. client and server

# Debian or Ubuntu
apt update && apt install iperf3

# OpenWrt
opkg update && opkg install iperf3

# CentOS/Red Hat Enterprise Linux
yum install iperf3

# Fedora
dnf install iperf3

# Run iPerf3 client and server

# Optional: Add iptables rule for iperf3 on server
iptables -I INPUT 1 -p tcp --dport 5201 -j ACCEPT

# Start iperf3 server
iperf3 -s

# Start iperf3 client and connect to server
iperf3 -c HOSTNAME_OR_IPV4_LITERAL_OR_IPV6_LITERAL

# Optional: Remove iptables rule for iperf3 on server
iptables -D INPUT -p tcp --dport 5201 -j ACCEPT

########################################
#
# Benchmark network throughput and/or bandwidth (Speed test) with iPerf2 and an AVM FRITZ!Box
#
# Ref.:
# https://service.avm.de/help/en/FRITZ-Box-Fon-WLAN-7490/016/hilfe_port_iperf
# https://www.pcwelt.de/ratgeber/Fritzbox-Hacks-Versteckte-Funktionen-freischalten-9957581.html
# https://stadt-bremerhaven.de/fritzbox-durchsatz-des-wlan-mit-iperf-messen/

# Install iPerf3 on your client

# Debian or Ubuntu
apt update && apt install iperf

# OpenWrt
opkg update && opkg install iperf

# CentOS/Red Hat Enterprise Linux
yum install iperf

# Fedora
dnf install iperf

# Run iPerf3 server

# Enable iPerf in the FRITZ!Box user interface
# Ref.: https://service.avm.de/help/en/FRITZ-Box-Fon-WLAN-7490/016/hilfe_port_iperf

# Optional: When Freetz is installed on your FRITZ!Box and you have a precompiled MIPS binary of iPerf2,
#           then you could also run the iperf server manually instead of enabling the builtin service.
iperf -s -w 256k

# Run iPerf3 client

# Connect to iPerf2 server on FRITZ!Box
iperf -c fritz.box -p 4711 -t 30 -w 256k
# or
iperf -c fritz.box -p 4711 -t 120 -i 10
# or
iperf -c fritz.box -p 4711 -d -w 256k -l 256k
# or
iperf --client fritz.box --port 4711 --dualtest --window 256k --len 256k

########################################
