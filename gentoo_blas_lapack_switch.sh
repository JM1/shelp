#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# BLAS/LAPACK runtime switch
#
# Ref.: https://wiki.gentoo.org/wiki/Blas-lapack-switch

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/make.conf

# BLAS/LAPACK runtime switch
# Ref.: https://wiki.gentoo.org/wiki/Blas-lapack-switch
USE="${USE} eselect-ldso"
EOF

emerge --ask --oneshot --verbose ">=virtual/blas-3.8" ">=virtual/lapack-3.8"
eselect blas list
eselect lapack list

# Example: Use OpenBLAS as default
emerge --ask --oneshot --verbose ">=sci-libs/openblas-0.3.5"
eselect blas set openblas
eselect lapack set openblas
