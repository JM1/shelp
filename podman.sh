#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2023 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Podman
#

########################################
# Offer files with Apache HTTP Server

URL='https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso'
FILE=$(curl --location --silent --remote-name --write-out %{filename_effective} "$URL")
FILEPATH=$(readlink -f "$FILE") # absolute
sudo podman run --security-opt=label=disable --publish 80:80 --rm --tty --interactive \
  --volume "$FILEPATH:/usr/local/apache2/htdocs/$FILE:ro" httpd:2.4

# in another tty
curl --location --head "http://$(hostname --fqdn)/$FILE" # test

########################################
