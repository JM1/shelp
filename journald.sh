#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# journald
#

cat << 'EOF' > /etc/systemd/journald.conf.d/fwd_to_tty12.conf
# 2019-2021 Jakob Meng, <jakobmeng@web.de>
# Forward journald to /dev/tty12
# Ref.:
#  man journald.conf
#  https://wiki.archlinux.org/title/Systemd/Journal#Forward_journald_to_/dev/tty12

[Journal]
ForwardToConsole=yes
TTYPath=/dev/tty12
#MaxLevelConsole=info
EOF

cat << 'EOF' > /etc/systemd/journald.conf.d/max_size.conf
# 2021 Jakob Meng, <jakobmeng@web.de>
# Enforce journald size limit
# Ref.:
#  man journald.conf
#  https://wiki.archlinux.org/title/Systemd/Journal#Journal_size_limit

[Journal]
SystemMaxUse=1G
EOF

cat << 'EOF' > /etc/systemd/journald.conf.d/no_syslog.conf
# 2021 Jakob Meng, <jakobmeng@web.de>
# Do not forward log messages to syslog daemon
# Ref.:
#  man journald.conf

[Journal]
ForwardToSyslog=no
EOF

# Enabling persistent logging in journald
# Ref.:
#  /usr/share/doc/systemd/README.Debian
#  https://unix.stackexchange.com/a/159390/188542
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
systemctl restart systemd-journald.service

########################################

# View logs

# sddm
sudo journalctl -b -u sddm

# X
journalctl -b 

########################################
