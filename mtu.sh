#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enable Jumbo frames a.k.a. increase MTU
# Ref.: https://linuxconfig.org/how-to-enable-jumbo-frames-in-linux

# find out mtu by testing different mtu values with
ip link set eth0 mtu 9000

vi /etc/network/interfaces
# Append 
#  mtu 9000
# to your iface entries.

# NOTE: On Debian 8 (Jessie) and earlier releases the option 'mtu' is not available 
# when using the manual method. Thus instead of specifying mtu directly you can
# use the post-up hook.
# Ref.: https://askubuntu.com/a/279364

# iface eth0 inet manual
#     post-up ip link set dev eth0 mtu 9000
