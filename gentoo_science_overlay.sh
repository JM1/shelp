#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Gentoo Science Overlay
#

# Enable
eselect repository enable science
emaint sync -a

# Disable and Remove
eselect repository remove science

########################################
#
# Install BLAS/LAPACK runtime switch from Gentoo Science Overlay
# and migrate app-admin/eselect and scientific libraries
#
# Ref.:
#  https://wiki.gentoo.org/wiki/User_talk:Houseofsuns
#  https://github.com/gentoo/sci/blob/master/README.md
#  https://github.com/gentoo/sci/issues/897
#  https://github.com/gentoo/sci/blob/master/scripts/lapack-migration.sh
#
# NOTE: This guide is out-of-date since Gentoo has a BLAS/LAPACK runtime switch!
#       Ref.: https://github.com/gentoo/sci/commit/e105f0f6a215d6fd15b58cb8a669e3f119c12169

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

[ ! -e "$GENTOO_PREFIX/etc/portage/package.mask" ] && mkdir "$GENTOO_PREFIX/etc/portage/package.mask/"
[ ! -d "$GENTOO_PREFIX/etc/portage/package.mask" ] && exit 255 # must be a directory not e.g. a file
cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/package.mask/sci-lapack
## mask packages superseded by science overlay
app-admin/eselect::gentoo
app-eselect/eselect-blas
app-eselect/eselect-cblas
app-eselect/eselect-lapack
virtual/blas::gentoo
virtual/cblas::gentoo
virtual/lapack::gentoo
sci-libs/gsl::gentoo
app-doc/blas-docs::gentoo
app-doc/lapack-docs::gentoo
sci-libs/blas-reference::gentoo
sci-libs/cblas-reference::gentoo
sci-libs/lapack-reference::gentoo
sci-libs/mkl::gentoo
EOF

emerge --ask --oneshot --verbose app-admin/eselect::science

FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose virtual/blas::science
FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose virtual/lapack::science

FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose sci-libs/blas-reference::science
eselect blas set reference

# sci-libs/cblas-reference::science does not build due to
# https://github.com/gentoo/sci/issues/734 and
# https://github.com/gentoo/sci/issues/878
#FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose sci-libs/cblas-reference::science
#eselect cblas set reference

FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose sci-libs/lapack-reference::science
eselect lapack set reference

# install app-portage/eix, e.g. follow section about 'app-portage/eix in gentoo_portage.sh

FEATURES="-preserve-libs":$FEATURES emerge --oneshot --ask --verbose \
    --exclude app-admin/eselect \
    --exclude sci-libs/blas-reference \
    --exclude sci-libs/cblas-reference \
    --exclude sci-libs/lapack-reference \
    `eix --only-names --installed --in-overlay science`

emerge --oneshot --ask --verbose @preserved-rebuild

####################
# Undo migration

rm $GENTOO_PREFIX/etc/portage/package.mask/sci-lapack

emerge --ask --oneshot --verbose app-admin/eselect::gentoo
FEATURES="-preserve-libs":$FEATURES emerge --ask --verbose --depclean sci-libs/lapacke-reference sci-libs/lapack-reference sci-libs/blas-reference virtual/blas virtual/cblas virtual/lapack sci-libs/scalapack
FEATURES="-preserve-libs":$FEATURES emerge --ask --verbose --unmerge sci-libs/lapacke-reference sci-libs/lapack-reference sci-libs/blas-reference virtual/blas virtual/cblas virtual/lapack sci-libs/scalapack

# Remove packages from Gentoo Science Overlay
pkgs=$(eix --only-names --installed-from-overlay science)
if [ -n "$pkgs" ]; then
    FEATURES="-preserve-libs":$FEATURES emerge --ask --verbose --depclean $pkgs
    FEATURES="-preserve-libs":$FEATURES emerge --ask --verbose --unmerge $pkgs
fi

rm -r $GENTOO_PREFIX/etc/env.d/alternatives/*
rmdir $GENTOO_PREFIX/etc/env.d/alternatives

emerge --oneshot --ask --verbose @preserved-rebuild

########################################
