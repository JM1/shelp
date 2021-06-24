#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Check and download upgradable packages automatically
#

########################################
# Using apt-daily.service / apt-daily.timer

cat << 'EOF' >> /etc/apt/apt.conf.d/90wana-periodic-update
// 2019 Jakob Meng, <jakobmeng@web.de>
// Check and download upgradable packages automatically
//
// Ref.:
//  /lib/systemd/system/apt-daily.service
//  /usr/lib/apt/apt.systemd.daily
//  /usr/share/doc/cron-apt/README.gz
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Verbose "1";
EOF

# test
/usr/lib/apt/apt.systemd.daily update

########################################
# Using cron-apt

apt install cron-apt

cat << EOF >> /etc/cron-apt/config.d/3-download
# 2011 Jakob Meng, <jakobmeng@web.de>
# Configuration Options in /usr/share/doc/cron-apt/README.gz

APTCOMMAND=/usr/bin/aptitude
MAILON="always"

EOF

########################################
