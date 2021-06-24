#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Change Docker root directory
# NOTE: Only works if docker's systemd init script has been patched to parse /etc/default/docker!
#
# Ref.:
#  https://github.com/docker/docker/issues/3127#issuecomment-35567785

service docker stop

# NOTE: Depending on your storage driver this might not work, e.g. with btrfs you should instead remove all images first
mv -i /var/lib/docker/ /STORAGE/

ln -s /STORAGE/docker/ /var/lib/docker

# Old docker versions
cat << 'EOF' >> /etc/default/docker
DOCKER_OPTS="-g $(readlink -f /var/lib/docker)"
EOF

# Newer docker versions
cat << 'EOF' >> /etc/default/docker
DOCKER_OPTS="--data-root $(readlink -f /var/lib/docker)"
EOF

service docker start

########################################
#
# Switching docker storage driver to overlay2
# NOTE: Guide only applies to Docker's own debian packages docker-ce..
#
# Ref.:
#  https://docs.docker.com/engine/userguide/storagedriver/selectadriver/
#  http://muehe.org/posts/switching-docker-from-aufs-to-devicemapper/

docker ps -a

# for each container you care for, stop and then commit it
docker commit e198aac7112d export/server1 
docker commit a312312fddde export/server2

# Save images to a tar archive
docker save export/server1 > export_server1.tar.gz
docker save export/server2 > export_server2.tar.gz

service docker stop

vi /etc/default/docker
# Change
#  DOCKER_OPTS="..."
# to
#  DOCKER_OPTS="... --storage-driver=overlay2"
# or
#  DOCKER_OPTS="... --storage-driver=btrfs"

systemctl daemon-reload

# (Optional) Remove old docker folder
rm ...

service docker start
docker info | grep 'Storage Driver:'

# Import the original images
docker load < export_server1.tar.gz
docker load < export_server2.tar.gz

########################################
