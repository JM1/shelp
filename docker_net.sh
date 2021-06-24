#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Change MTU of default docker bridge
#
# Ref.:
#  https://docs.docker.com/network/bridge/#use-the-default-bridge-network
#  https://docs.docker.com/engine/reference/commandline/network_create/
#  https://superuser.com/questions/995373/remove-docker0-bridge/995382#995382

systemctl stop docker
ip link del docker0

cat << 'EOF' >> /etc/docker/daemon.json
{
    "mtu": 9000
}
EOF

# Or instead if docker's systemd init script has been patched to parse /etc/default/docker:
cat << 'EOF' >> /etc/default/docker
DOCKER_OPTS="--mtu 9000"
EOF

systemctl daemon-reload
systemctl start docker

docker network inspect bridge
# ifconfig does not show changed mtu

########################################
#
# Set docker NICs as manually configured, so that NetworkManager ignores them
#

cat << 'EOF' >> /etc/network/interfaces

# Listing docker NICs here will cause NetworkManager to ignore them.
iface docker0 inet manual
iface docker1 inet manual
iface docker2 inet manual
iface docker3 inet manual
iface docker4 inet manual
iface docker5 inet manual
iface docker6 inet manual
iface docker7 inet manual
iface docker8 inet manual
iface docker9 inet manual

EOF
service network-manager restart

########################################
