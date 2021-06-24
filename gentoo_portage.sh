#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# portage package management
#

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

# Updating the Gentoo repository
# Ref.: https://wiki.gentoo.org/wiki/Handbook:X86/Working/Portage#Updating_the_Gentoo_repository
emaint sync -a
# or
emerge --sync # deprecated, see https://wiki.gentoo.org/wiki/Project:Portage/Sync

# Update portage
emerge --ask --verbose --oneshot portage

# Updating the system
# Ref.: https://wiki.gentoo.org/wiki/Handbook:X86/Working/Portage#Updating_the_system
emerge --ask --update --deep --with-bdeps=y --newuse @world
# NOTE: After @world updates, it is important to remove obsolete packages with 'emerge --depclean', see below!

# After updating a library, update all depending packages that are still built against the old version of this library
# Ref.: https://wiki.gentoo.org/wiki/Preserved-rebuild
emerge --oneshot --ask --verbose @preserved-rebuild

# Remove obsoleted distfiles
# Ref.: https://wiki.gentoo.org/wiki/Knowledge_Base:Remove_obsoleted_distfiles
eclean-dist --pretend

# emerge e.g. equery
# Ref.: https://wiki.gentoo.org/wiki/Equery/de
emerge --ask app-portage/gentoolkit

# Avoiding an atom in the world file
emerge --ask --oneshot <category/atom>

# List packages
equery list '*'
equery list @world
equery list @selected

# List packages installed from overlay
eix --installed-from-overlay science

# List packages that depend on a package
equery depends PKG

# List profiles
eselect profile list

# Remove a package (that no other packages depend on)
emerge --ask --verbose --clean sys-cluster/ucx

# Remove a package (even if it is needed by other packages)
emerge --ask --verbose --unmerge sys-cluster/ucx

# Removing packages that are not associated with explicitly merged packages
emerge --ask --update --newuse --deep @world
emerge --depclean --ask --verbose

# Getting dependency graphs
# Ref.: https://wiki.gentoo.org/wiki/Equery/de#Getting_dependency_graphs_with_depgraph_.28g.29
equery depgraph x11-libs/xforms --depth 5

# read news after emerge
# "
#  * IMPORTANT: 13 news items need reading for repository 'gentoo'.
#  * Use eselect news read to view new items.
# "
eselect news read

# List the package that owns FILE
# Ref.: man equery
equery belongs /usr/include/GL/gl.h

# View world set
cat $GENTOO_PREFIX/var/lib/portage/world

# Remove atoms and/or sets from the world file a.k.a. mark package as automatically emerged
# Ref.: man emerge
emerge --ask --deselect media-libs/mesa

# Mark a package as manually installed a.k.a. add atom to
# /var/lib/portage/world file without compiling it again.
# Ref.: https://wiki.gentoo.org/wiki/Selected_set_(Portage)#Adding_an_atom_without_recompilation
emerge --ask --noreplace sys-cluster/openmpi

# Rebuild a package
emerge --ask --emptytree --nodeps --oneshot sys-fabric/libibverbs

# Mask/Pin a package
cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/package.mask
# do not emerge OpenMPI >2.0.2
>sys-cluster/openmpi-2.0.2
EOF

# List repository details
# Ref.: https://wiki.gentoo.org/wiki/Ebuild_repository
portageq repos_config $GENTOO_PREFIX
# or
emerge --info --verbose # look for the "Repositories"

# Rebuild whole system / all packages
# Ref.: http://www.mgreene.org/?p=159
emerge --ask --verbose --emptytree @world

# Permit all licenses, except End User License Agreements that require
# reading and signing an acceptance agreement. Note that this will
# also accept non-free software and documentation.
# Ref.: https://www.gentoo.org/support/news-items/2019-05-23-accept_license.html
cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/make.conf

# Permit all licenses, except EULAs that require reading and signing an acceptance agreement
ACCEPT_LICENSE="* -@EULA"
EOF

####################
# app-portage/eix
# "eix is a set of utilities for searching and diffing local ebuild repositories using a binary cache."
#
# Ref.:
#  https://wiki.gentoo.org/wiki/Eix

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

emerge --ask --oneshot --verbose app-portage/eix
[ ! -d "$GENTOO_PREFIX/var/cache/eix/" ] && mkdir "$GENTOO_PREFIX/var/cache/eix/"
eix-update

# Search for packages installed from 'science' overlay
eix --only-names --installed --in-overlay science

####################
# Configuration file updates
#
# For example, if emerge warns about required configuration file updates:
# "
#  * IMPORTANT: 2 config files in ... need updating.
#  * See the CONFIGURATION FILES and CONFIGURATION FILES UPDATE TOOLS
#  * sections of the emerge man page to learn how to update config files.
# "
# 
# Ref.:
#  man emerge # sections CONFIGURATION FILES and CONFIGURATION FILES UPDATE TOOLS
#  man dispatch-conf
#  man etc-update

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

dispatch-conf
etc-update

# list remaining config files
find "${GENTOO_PREFIX}/etc" -name \._cfg\* -print
# this should not output anything after etc-update and dispatch-conf


####################
# USE flags

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

# Simple USE flags configuration
# Ref.: https://wiki.gentoo.org/wiki/Ufed
emerge --ask app-portage/ufed
ufed

# set global USE flags
cat << 'EOF' >> $GENTOO_PREFIX/etc/portage/make.conf

USE="$USE qt5"
EOF

# set local (per package) USE flags
mkdir $GENTOO_PREFIX/etc/portage/package.use
cat << 'EOF' > $GENTOO_PREFIX/etc/portage/package.use/app-arch_libarchive
app-arch/libarchive -e2fsprogs
EOF

# Adapting the entire system to the new USE flags
# Ref.: https://wiki.gentoo.org/wiki/Handbook:Parts/Working/USE#Adapting_the_entire_system_to_the_new_USE_flags
emerge --ask --update --deep --newuse @world
#emerge -p --depclean
emerge --ask --depclean
revdep-rebuild

####################
# Create list of packages that Portage should assume have been provided
# Ref.: https://wiki.gentoo.org/wiki//etc/portage/profile/package.provided

mkdir -p $GENTOO_PREFIX/etc/portage/profile/package.provided
cat << 'EOF' > $GENTOO_PREFIX/etc/portage/profile/package.provided/dev-util_cmake-3.13.4
dev-util/cmake-3.13.4
EOF

####################
