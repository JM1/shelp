#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Docker Setup
#

####################
# On Debian 8 (Jessie)
# Ref.: https://docs.docker.com/engine/installation/linux/debian/

apt-get install apt-transport-https

cat << 'EOF' > /etc/apt/sources.list.d/apps-docker.list
# 2016 Jakob Meng, <jakobmeng@web.de>
# Docker
# Reference: https://docs.docker.com/engine/installation/linux/debian/

deb https://apt.dockerproject.org/repo debian-jessie main
EOF

cat << 'EOF' > /etc/apt/preferences.d/apps-docker.pref
# 2016 Jakob Meng, <jakobmeng@web.de>
# Docker

Package: docker-engine
Pin: release o=Docker
Pin-Priority: 500

Package: *
Pin: release o=Docker
Pin-Priority: -50
EOF

apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-get update

apt-get install --no-install-recommends docker-engine # recommends not installed because this pulls in plymouth which conflicts with console-common

service docker status

####################
# On Debian 10 (Buster)
apt install docker.io

####################
