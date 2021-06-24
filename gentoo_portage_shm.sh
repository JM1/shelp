#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Compile inside memory
# Ref.: https://wiki.gentoo.org/wiki/Project:Prefix/FAQ#Compile_inside_memory

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

cat << 'EOF' >> "${GENTOO_PREFIX}/etc/portage/make.conf"

# Compile inside memory
PORTAGE_TMPDIR=/dev/shm
EOF

# or
cat << 'EOF' >> "${GENTOO_PREFIX}/etc/portage/make.conf"

# Compile inside memory
PORTAGE_TMPDIR=/tmp
EOF

# or
export PORTAGE_TMPDIR=/dev/shm

# or
export PORTAGE_TMPDIR=/tmp
