#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# libpod / Podman on Gentoo
#

# workaround a bug in app-emulation/slirp4netns-0.3.0_beta1::gentoo 
# where glib-2.0 is required but not a build dependency
emerge --ask dev-libs/glib

# sys-apps/iproute2-4.20.0 fails with "Aborting due to QA concerns: there are 
# files installed outside the prefix" so we temporarily disable this test.
[ -n "$GENTOO_PREFIX" ] && \
 chmod a-rwx "$GENTOO_PREFIX"/usr/lib64/portage/python3.6/install-qa-check.d/05prefix

emerge --ask app-emulation/libpod

[ -n "$GENTOO_PREFIX" ] && \
 chmod a+rx,u+w "$GENTOO_PREFIX"/usr/lib64/portage/python3.6/install-qa-check.d/05prefix

# * Messages for package app-emulation/libpod-1.1.2:
#
# * You need to create the following config files:
# * /etc/containers/registries.conf
# * /etc/containers/policy.json
# * To copy over default examples, use:
# * cp /etc/containers/registries.conf{.example,}
# * cp /etc/containers/policy.json{.example,}
# * 
# * For rootless operation, you need to configure subuid/subgid
# * for user running podman. In case subuid/subgid has only been
# * configured for root, run:
# * usermod --add-subuids 1065536-1131071 <user>
# * usermod --add-subgids 1065536-1131071 <user>
cd "$GENTOO_PREFIX"/etc/containers/
cp -raiv registries.conf.example registries.conf
cp -raiv policy.json.example policy.json

# ask root to add subuids and subgids for user,
# e.g. 
#  sudo usermod --add-subuids 10000-75535 USERNAME
#  sudo usermod --add-subgids 10000-75535 USERNAME
#
# Ref.: https://github.com/containers/libpod/blob/master/docs/podman.1.md#rootless-mode

# Removal
emerge --depclean --ask --verbose app-emulation/libpod
emerge --depclean --ask --verbose dev-libs/glib
emerge --depclean --ask --verbose
