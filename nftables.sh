#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# nftables
#
# NOTE: "A Linux kernel >= 3.13 is required. However, >= 4.14 is recommended." [4]
#
# NOTE: "Debian 10 (Buster) uses the nftables framework by default." [1]
#
# Ref.:
# [1] https://wiki.debian.org/nftables
# [2] man nft
# [3] /usr/share/doc/nftables/examples/README
# [4] https://packages.debian.org/en/stable/nftables

# Debian 9 (Stretch) and later
apt install nftables
systemctl enable nftables.service
