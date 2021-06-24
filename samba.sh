#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Samba
#

# List all Samba users
pdbedit -L -v

# Add new Samba user
pdbedit -a -u johnwayne

# Deprecated commands
#smbpasswd -e [username]
#smbpasswd -d [username]
#pdbedit -Lv [username]

# Restart Windows system using Samba
net rpc shutdown -C "Updates installed. Reboot required." -I 192.168.0.10 -U johnwayne -r -f -t 15
# -r = restart
# -f = force

# mount remote folder
smbmount //saloon.wildwildwest.com/windows /mnt/ -o username=johnwayne,uid=1000
