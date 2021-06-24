#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Disable SSH Password Authentication (OpenSSH)
#

# Before Debian 10 (Buster)
sed -i -e 's/^#*PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl restart ssh.service
#
# On Debian 10 (Buster)
sed -i -e 's/^#*PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config
# NOTE: Answers to openssh-server's debconf questions such as 'openssh-server/password-authentication' are not applied
#       when dpkg-reconfigure is called with noninteractive frontend and /etc/ssh/sshd_config does exist already.
#       Instead /etc/ssh/sshd_config has to be changed explicitly. But calling dpkg-reconfigure is useful anyway because
#       this will update the debconf database according to the current values in /etc/ssh/sshd_config so that during
#       updates debconf will not complain about config changes on the next package update.
# Ref.: /var/lib/dpkg/info/openssh-server.postinst
dpkg-reconfigure -f noninteractive openssh-server
systemctl restart ssh.service
#
# On Debian 11 (Bullseye)
cat << 'EOF' >> /etc/ssh/sshd_config.d/no_password_authentication.conf
# 2021 Jakob Meng, <jakobmeng@web.de>
PasswordAuthentication no
EOF
systemctl restart ssh.service

# debug sshd config
sshd -T
