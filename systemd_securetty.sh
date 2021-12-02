#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Allow passwordless root login on the serial console /dev/ttyS1
#
# Debian 10 (Buster)
# Debian 11 (Bullseye)
#
# Ref.:
# https://unix.stackexchange.com/questions/552576/allow-passwordless-root-login-on-the-serial-console
# https://wiki.archlinux.org/title/Automatic_login_to_virtual_console
# https://blog.oddbit.com/post/2020-02-24-a-passwordless-serial-console/
# https://manpages.debian.org/bullseye/libpam-modules/pam_rootok.8.en.html
# https://manpages.debian.org/bullseye/libpam-modules/pam_securetty.8.en.html
# https://manpages.debian.org/bullseye/libpam-runtime/pam.conf.5.en.html

dash # bash interprets tabs which causes problems

# Create pam config for pam_securetty.so
cat << 'EOF' > /usr/share/pam-configs/securetty
Name: Enable pam_securetty.so
Default: no
Priority: 512
Auth-Type: Primary
Auth:
	[success=ok auth_err=1]	pam_rootok.so
	[success=done default=ignore]	pam_securetty.so noconsole
EOF

exit

# Enable pam config for pam_securetty.so
pam-auth-update --enable securetty

# Allow root login without password on /dev/ttyS1
cat << 'EOF' > /etc/securetty
ttyS1
EOF

# Do not leak info about passwordless tty
chmod u=rw,g=,o= /etc/securetty

# start login shell on /dev/ttyS1
mkdir /etc/systemd/system/serial-getty@ttyS1.service.d

cat << 'EOF' > /etc/systemd/system/serial-getty@ttyS1.service.d/override.conf
# 2021 Jakob Meng, <jakobmeng@web.de>
# Allow logins via serial console
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -- \\u' 115200 %I $TERM
# Other options
# Ref.: man agetty
#ExecStart=-/sbin/agetty -o '-p -- \\u' --keep-baud 115200,57600,38400,19200,9600 --noclear --autologin root %I $TERM
EOF

systemctl daemon-reload

# Or use systemctl to add contents to /etc/systemd/system/serial-getty@ttyS1.service.d/override.conf
systemctl edit serial-getty@ttyS1.service

# Start login shell on /dev/ttyS1 now and on boots
systemctl enable --now serial-getty@ttyS1.service

# Show last logins
last
