#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# make foreign i386 (x86/32 Bit) chroot on amd64 (x86_x64/x86/64 Bit) system using debootstrap
#

DIR="/opt/jessie-i386"
debootstrap --foreign --arch=i386 jessie "$DIR" http://ftp.de.debian.org/debian
# NOTE: Maybe you have to bind-mount /dev/ and /sys/ as well.
chroot "$DIR" /debootstrap/debootstrap --second-stage

########################################
