#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Cleanup package cache intervals periodically
#

# "clean clears out the local repository of retrieved package files. It removes
#  everything but the lock file from /var/cache/apt/archives/ and
#  /var/cache/apt/archives/partial/."
#
# "Like clean, autoclean clears out the local repository of retrieved package
#  files. The difference is that it only removes package files that can no longer
#  be downloaded, and are largely useless. This allows a cache to be maintained
#  over a long period without it growing out of control."
#
# Ref.: man apt-get

cat << 'EOF' > /etc/apt/apt.conf.d/90wana-periodic-clean
// 2018-2019 Jakob Meng, <jakobmeng@web.de>
// Cleanup package cache intervals periodically
//
// Ref.:
//  /etc/cron.daily/apt            on Debian 8 (Jessie)
//  /usr/lib/apt/apt.systemd.daily on Debian 9 (Stretch) and Debian 10 (Buster)

// Do "apt-get autoclean" every n-days (0=disable)
APT::Periodic::AutocleanInterval "15";

// Do "apt-get clean" every n-days (0=disable)
// Requires Debian 9 (Stretch) or later
APT::Periodic::CleanInterval "30";

EOF
