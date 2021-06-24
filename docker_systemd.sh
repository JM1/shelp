#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Patch docker's systemd init script so that /etc/default/docker is parsed
#

[ ! -e /etc/systemd/system/docker.service.d/ ] && mkdir -p /etc/systemd/system/docker.service.d/
cat << 'EOF' > /etc/systemd/system/docker.service.d/docker.conf
# 2016-2018 Jakob Meng, <jakobmeng@web.de>
# Load /etc/default/docker from SystemD init script
# References: 
#  https://github.com/docker/docker/issues/9889#issuecomment-120927382
#  https://gist.github.com/nickjacob/9909574

[Service]
# This line is sufficient if DOCKER_OPTS variable does not have to be expanded:
#EnvironmentFile=-/etc/default/docker
# Use this line to expand DOCKER_OPTS variable:
ExecStartPre=/bin/sh -c ". /etc/default/docker && /bin/systemctl set-environment DOCKER_OPTS=\"$DOCKER_OPTS\""

ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_OPTS
# or
#ExecStart=/usr/bin/dockerd -H unix:// $DOCKER_OPTS

ExecStopPost=/bin/sh -c "/bin/systemctl unset-environment DOCKER_OPTS"

EOF

systemctl daemon-reload
service docker restart

########################################
