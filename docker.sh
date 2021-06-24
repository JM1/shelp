#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Docker
#

########################################
# Allow regular user to use docker
#
# ATTENTION: Read 'Docker daemon attack surface' from
# https://docs.docker.com/engine/security/security/#docker-daemon-attack-surface before!

adduser johnwayne docker

########################################
#
# Pull and log into a container
#

CTNR=ocaml/opam
docker pull ${CTNR}
docker run -ti ${CTNR} bash

docker run ...
# Mount a host directory as a data volume
# Reference:
#  https://docs.docker.com/engine/tutorials/dockervolumes/
 -ti -v /HOST-DIR:/CONTAINER-DIR
# or
 -ti -v /HOST-DIR:/CONTAINER-DIR:ro
# or
 -ti -v /HOST-FILE:/CONTAINER-FILE
# or
 -ti -v /HOST-FILE:/CONTAINER-FILE:ro

# Assign a name to instance
 --name "${CTNR}-running-$(date +%Y%m%d%H%M%S)"

# Automatically remove the container when it exits (incompatible with -d)
 --rm

... bash

########################################
#
# Remove all existing containers (not images!)
#
# Reference:
#  https://stackoverflow.com/a/17870293/6490710
docker rm $(docker ps -aq)

########################################
#
# Remove image
#

CTNR=ocaml/opam
docker rmi ${CTNR}

########################################
#
# Create a docker container
#

cd /tmp

CTNR=ocaml-ctnr-1
mkdir "$CTNR" && cd "$CTNR"

cat << 'EOF' >> Dockerfile
FROM ocaml/opam
RUN opam depext -i core utop
EOF

docker build -t "$CTNR" .

########################################
#
# Manually creating Docker images
#
# References
#  https://greek0.net/blog/2015/04/30/homegrown_docker_images/
#  https://github.com/tianon/docker-brew-debian/tree/master


sudo -s

# Option '-d ...' is only required if directory /var/tmp/ is mounted with noexec or nodev
# For --include see https://github.com/tianon/docker-brew-debian/blob/master/stretch/include
/usr/share/docker-engine/contrib/mkimage.sh \
  -t wana/debian-stretch \
  -d /tmp/wana_debian-stretch \
  debootstrap --variant=minbase --include='inetutils-ping,iproute2' stretch \
  http://httpredir.debian.org/debian

########################################
