#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# TFTP server
#

################################################################################
#
# TFTP server using TFTPy
#

# install tftp server
sudo -s
apt-get install python-tftpy
exit

# run tftp server
sudo -s
mkdir /tmp/tftp
python << 'EOF'
import tftpy

server = tftpy.TftpServer('/tmp/tftp')
server.listen('0.0.0.0', 69)
EOF

################################################################################
#
# TFTP server using dnsmasq
#
# Ref.:
#  man dnsmasq
#  https://ssl.hehoe.de/artikel/blog/dnsmasq-fur-pxe-boot.html

apt install dnsmasq-base # full package dnsmasq is not required

# Kill all running instances if dnsmasq fails with error message
#  dnsmasq: failed to bind DHCP server socket: Address already in use
killall dnsmasq

# Run dnsmasq as a DHCP server in background, argument '--port=0' will disable dnsmasq's DNS function.
LANG=C dnsmasq --conf-file=/dev/null --port=0 --enable-tftp=eth0 --tftp-root=/var/tftp

# Stop dnsmasq
killall dnsmasq

################################################################################
