#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enable user namespaces for containers
# NOTE: Only works if docker's systemd init script has been patched to parse /etc/default/docker (docker_systemd.sh)!
#
# References:
#  man dockerd

# WARNING: Enabling user namespaces for containers cause several problems, e.g. "docker build ..." fails during
#          container builds with /usr/share/docker-ce/contrib/mkimage.sh and permissions in mounted volumes must be
#          set for container users.
#
#          "However user namespaces are currently not really deployable for other reasons: the OS images need manual UID
#          shifting and there's no known, sane, established scheme to allocate UID ranges from the host.
#          Or in other words: don't pretend you could lock things down properly right now, with just namespaces, and 
#          keep things generic enough. Sorry."
#          Ref.: https://www.freedesktop.org/wiki/Software/systemd/ContainerInterface/

# NOTE: "... any images you had originally pulled will be gone. ... remapped engine will basically operate in a new
#       environment (in the 100000.100000 directory). Every remapping will get its own directory (format XXX.YYY where
#       XXX is the subordinate UID and YYY is the subordinate GID) - we can look in there and see it's essentially a 
#       new, isolated /var/lib/docker..."
#       Ref.: https://success.docker.com/article/introduction-to-user-namespaces-in-docker-engine

systemctl stop docker

# you may want to remove all images and anything /var/lib/docker/ now

# Specifying "default" will cause a new user and group to be created to handle UID and
# GID range remapping for the user namespace mappings used for contained processes.
cat << 'EOF' >> /etc/default/docker
DOCKER_OPTS="--userns-remap=default"
EOF

systemctl daemon-reload
systemctl start docker
