#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Patch debian package sources
#
# Ref.:
#  man quilt
#  https://wiki.debian.org/UsingQuilt

################################################################################

# More quilt comands
quilt pop -a # undo all patches
quilt pop # remove topmost patch from stack of applied patches
quilt refresh # refresh the topmost patch
quilt push # apply next patch in the series file
quilt push -a # redo all patches

################################################################################
# example for patch editing
#
# NOTE: Assume that all patches from debian/patches/series have 
# been applied and the last three patches returned by
#  cat debian/patches/series
# are
#  wana/grub2-wana001.patch
#  wana/grub2-wana002.patch
#  wana/grub2-wana003.patch

####################
# how to edit files from patch grub2-wana003.patch

# edit files
vi ...
# refresh last patch, which is wana/grub2-wana003.patch
quilt refresh

####################
# how to edit files from patch wana/grub2-wana002.patch

# first undo patch wana/grub2-wana003.patch
quilt pop

# now edit files
vi ...

# refresh patch wana/grub2-wana002.patch
quilt refresh

# reapply wana/grub2-wana003.patch
quilt push

################################################################################
