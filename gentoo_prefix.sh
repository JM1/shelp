#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup a Gentoo system using Gentoo Prefix
#
# Ref.:
#  https://wiki.gentoo.org/wiki/Project:Prefix/Bootstrap

export GENTOO_PREFIX=$HOME/gentoo

export PORTAGE_TMPDIR=/dev/shm
# or
export PORTAGE_TMPDIR=/tmp

wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh
chmod +x bootstrap-prefix.sh
./bootstrap-prefix.sh
# or
./bootstrap-prefix.sh "$GENTOO_PREFIX" noninteractive
# or
./bootstrap-prefix.sh "$GENTOO_PREFIX" stage1
./bootstrap-prefix.sh "$GENTOO_PREFIX" stage2
./bootstrap-prefix.sh "$GENTOO_PREFIX" stage3

# jump into gentoo
"$GENTOO_PREFIX"/startprefix
export GENTOO_PREFIX=$HOME/gentoo

[ -z "$GENTOO_PREFIX" ] && echo 'GENTOO_PREFIX is not set, check your .bashrc !!!'

####################
# Useful software

emerge --ask app-shells/bash app-shells/bash-completion
emerge --ask app-portage/gentoolkit
emerge --ask app-editors/vim

emerge --ask app-misc/screen
[ "$GENTOO_PREFIX" != "/" ] && chmod 777 $GENTOO_PREFIX/tmp/screen

# To permit all licenses except EULAs, change ACCEPT_LICENSE in $GENTOO_PREFIX/etc/portage/make.conf
# For details read guide gentoo_portage.sh

####################
#
# Configure locales
#
# Demanded during bootstrap:
# "
#  * Could not find a UTF-8 locale. This may trigger build failures in
#  * some python packages. Please ensure that a UTF-8 locale is listed in
#  * /etc/locale.gen and run locale-gen.
# "

# Ref.: https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation#Configure_locales
cat << EOF >> "$GENTOO_PREFIX/etc/locale.gen"
en_US ISO-8859-1
en_US.UTF-8 UTF-8
de_DE ISO-8859-1
de_DE.UTF-8 UTF-8
EOF

locale-gen

# If this command fails with
# "
#  * Using locale.gen from ROOT $GENTOO_PREFIX/$GENTOO_PREFIX/etc/
#  * Sorry, but ROOT support is incomplete at this time.
# "
# then instead run:
locale-gen --destdir "$GENTOO_PREFIX/"

####################
#
# Configuration file updates as asked for during bootstrap:
# "
#  * IMPORTANT: config file '$GENTOO_PREFIX/etc/hosts' needs updating.
#  * See the CONFIGURATION FILES and CONFIGURATION FILES UPDATE TOOLS
#  * sections of the emerge man page to learn how to update config files.
# "
# Follow section about configuration file updates in guide gentoo_portage.sh

####################
#
# Read news
#
# Demanded during bootstrap:
# "
#  * IMPORTANT: 13 news items need reading for repository 'gentoo'.
#  * Use eselect news read to view new items.
# "
eselect news read

####################
#
# Mask configurations that could potentially break the system
#

cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/profile/use.mask

# Use flag 'pam' cause emerge failures, e.g. of dev-libs/libcgroup,
# sys-libs/pam, sys-libs/libcap and sys-cluster/slurm.
#
# USE=pam does not make sense in Prefix system.
# Should be using the host auth system. [1]
#
# sys-libs/pam is not essential in a Prefix system, but is pulled in as
# a dependency by every package with use flag 'pam' if not masked [2].
#
# Ref.:
# [1] https://gitweb.gentoo.org/repo/gentoo.git/tree/profiles/features/prefix/rpath/use.mask
# [2] https://bugs.gentoo.org/695966
pam
EOF

####################
#
# CMake
#

# CMake searchs for e.g. Find*.cmake, CMake modules, C/C++/Fortran headers and sources in system paths like /usr,
# which must be disabled or else all sorts of problems can happen, e.g. header/library version mismatchs or CMake
# fails to emerge/build on wr0.wr.inf.h-brs.de because during configure it finds Qt5 from system paths and then
# fails in /usr/lib64/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake because it cannot find GL/gl.h in /usr/include/libdrm!

# will be passed to 'cmake -C ...'
cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/env/cmake.cmake
set(CMAKE_SYSROOT "$ENV{GENTOO_PREFIX}" CACHE STRING "")
set(CMAKE_FIND_ROOT_PATH "$ENV{GENTOO_PREFIX}" CACHE STRING "")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER CACHE STRING "")
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER CACHE STRING "")
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER CACHE STRING "")
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE NEVER CACHE STRING "")
EOF

# variable substition does not work in *.conf files
cat << EOF >> $GENTOO_PREFIX/etc/portage/env/cmake.conf
CMAKE_EXTRA_CACHE_FILE="$GENTOO_PREFIX/etc/portage/env/cmake.cmake"
EOF

cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/package.env
*/* cmake.conf
EOF

emerge --ask --verbose dev-util/cmake

##########
# (Optional) If emerge still fails you might want to consider downloading and installing a prebuilt CMake:
mkdir -p $GENTOO_PREFIX/etc/portage/profile/package.provided
cat << 'EOF' > $GENTOO_PREFIX/etc/portage/profile/package.provided/dev-util_cmake-3.13.4
dev-util/cmake-3.13.4
EOF

lynx -listonly -dump https://cmake.org/files/LatestRelease/ |
 awk '/^[ ]*[1-9][0-9]*\./{sub("^ [^.]*.[ ]*","",$0); print;}' |
 grep '.*\/cmake-[0-9]*\.[0-9]*\.[0-9]*-Linux-x86_64\.tar\.gz' |
 tail -n 1 |
 xargs curl -s |
 tar -x -z --strip-components 1 -C "$GENTOO_PREFIX/usr/local/"

cd "$GENTOO_PREFIX"/usr/portage/dev-util/cmake/files/
# First compare patches to and select patches from
# https://gitweb.gentoo.org/repo/gentoo.git/tree/dev-util/cmake/cmake-3.14.1.ebuild
#
# Skipped due to issues:
#  cmake-3.14.0_rc1-FindLAPACK.patch

cat \
    cmake-3.4.0_rc1-darwin-bundle.patch \
    cmake-3.14.0_rc3-prefix-dirs.patch \
    cmake-3.14.0_rc1-FindBLAS.patch \
    cmake-3.5.2-FindQt4.patch \
    cmake-2.8.10.2-FindPythonLibs.patch \
    cmake-3.9.0_rc2-FindPythonInterp.patch \
    cmake-3.11.4-fix-boost-detection.patch \
        | patch -d "$GENTOO_PREFIX/usr/local/share/cmake-3.14/" -p1 

########################################
# Q&A, FAQ, Workarounds

####################
# If emerge fails with errors like
#  "Aborting due to QA concerns: invalid shebangs found"
# or
#  "Aborting due to QA concerns: there are files installed outside the prefix"
# then disable prefix qa tests temporarily:

chmod a-rwx "$GENTOO_PREFIX"/usr/lib64/portage/python3.6/install-qa-check.d/05prefix
emerge...
chmod a+rx,u+w "$GENTOO_PREFIX"/usr/lib64/portage/python3.6/install-qa-check.d/05prefix

# NOTE: THIS IS A BAD IDEA! BETTER PATCH YOUR FAILING EBUILDS!!!

##########
# As an alternative you can disable only specific errors in prefix qa tests, e.g. you can
# (re)install bash by disabling only "Aborting due to QA concerns: invalid shebangs found".

bash --norc --noediting

cat << 'EOF' | patch -p0 -d "$GENTOO_PREFIX"
--- usr/lib64/portage/python3.6/install-qa-check.d/05prefix.orig	2019-03-14 20:12:18.542429998 -0000
+++ usr/lib64/portage/python3.6/install-qa-check.d/05prefix	2019-03-14 20:12:51.305431786 -0000
@@ -107,7 +107,7 @@
 			eqawarn "  ${line}"
 		done < "${T}"/non-prefix-shebangs-errs
 		rm -f "${T}"/non-prefix-shebangs-errs
-		die "Aborting due to QA concerns: invalid shebangs found"
+		#die "Aborting due to QA concerns: invalid shebangs found"
 	fi
 }
 
EOF

emerge --update app-shells/bash

cat << 'EOF' | patch -p0 -d "$GENTOO_PREFIX"
--- usr/lib64/portage/python3.6/install-qa-check.d/05prefix.orig	2019-03-14 20:12:18.542429998 -0000
+++ usr/lib64/portage/python3.6/install-qa-check.d/05prefix	2019-03-14 20:12:51.305431786 -0000
@@ -107,7 +107,7 @@
 			eqawarn "  ${line}"
 		done < "${T}"/non-prefix-shebangs-errs
 		rm -f "${T}"/non-prefix-shebangs-errs
-		#die "Aborting due to QA concerns: invalid shebangs found"
+		die "Aborting due to QA concerns: invalid shebangs found"
 	fi
 }
 
EOF

exit

########################################
