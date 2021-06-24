#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# eselect/repository
#
# "This utility supersedes app-admin/layman for listing, configuring, and handling
#  synchronization of alternate repositories except for version control systems which the
#  package manager does not natively sync (eg. mercurial, bazaar, and g-sorcery in Portage)."
#
# Ref.:
#  https://wiki.gentoo.org/wiki/Eselect/Repository

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

# Default repositories
cat $GENTOO_PREFIX/usr/share/portage/config/repos.conf

emerge --ask app-eselect/eselect-repository
[ ! -e $GENTOO_PREFIX/etc/portage/repos.conf ] && \
 mkdir -p $GENTOO_PREFIX/etc/portage/repos.conf

# Show uri to repository list
grep REMOTE_LIST_URI $GENTOO_PREFIX/etc/eselect/repository.conf

# Listing registered repositories
eselect repository list # -i to list installed repositories only
# Searchable online: https://repos.gentoo.org/

# Add registered repositories
eselect repository enable junkdrawer
emaint sync -a
# Repositories get copied to $GENTOO_PREFIX/var/db/repos

# Disable repositories without removing contents
eselect repository disable junkdrawer

# Disable repositories and remove contents
eselect repository remove junkdrawer

# Show current repository configuration
portageq repos_config $GENTOO_PREFIX

# Change repository priority
vi $GENTOO_PREFIX/etc/portage/repos.conf/eselect-repo.conf # Add or change line 'priority = -2000'

########################################
#
# Custom repository
#
# Ref.:
#  https://wiki.gentoo.org/wiki/Custom_repository
#  https://uhlenheuer.net/posts/2015-07-22-gentoo_local_overlay.html
#  https://wiki.gentoo.org/wiki/Handbook:AMD64/Portage/CustomTree#Defining_a_custom_repository
#  https://devmanual.gentoo.org/quickstart/

export GENTOO_PREFIX=$HOME/gentoo
# or
export GENTOO_PREFIX=/

# Prerequisites
emerge --ask app-portage/repoman

####################
# Defining a custom repository
mkdir -p $GENTOO_PREFIX/usr/local/portage/{metadata,profiles}
chown -R portage:portage $GENTOO_PREFIX/usr/local/portage
REPONAME=localrepo # change to a sensible name for the repository
echo "$REPONAME" > $GENTOO_PREFIX/usr/local/portage/profiles/repo_name

cat << 'EOF' > $GENTOO_PREFIX/usr/local/portage/metadata/layout.conf
masters = gentoo
auto-sync = false
EOF

####################
# Enable repository on local system
cat << EOF >> $GENTOO_PREFIX/etc/portage/repos.conf/$REPONAME.conf
[$REPONAME]
location = $GENTOO_PREFIX/usr/local/portage
EOF

####################
# Adding an ebuild to local repository
PN=rdma-core
CATEGORY=sys-fabric
PV=23

mkdir -p $GENTOO_PREFIX/usr/local/portage/$CATEGORY/${PN}
cp ~/${PN}-${PV}.ebuild $GENTOO_PREFIX/usr/local/portage/${CATEGORY}/${PN}/${PN}-${PV}.ebuild
chown -R portage:portage $GENTOO_PREFIX/usr/local/portage
pushd $GENTOO_PREFIX/usr/local/portage/${CATEGORY}/${PN}
repoman manifest
popd

####################
# install ebuild from local repository
emerge --ask --verbose           $PN
emerge --ask --verbose $CATEGORY/$PN
emerge --ask --verbose $CATEGORY/$PN-${PV}
emerge --ask --verbose $CATEGORY/$PN-${PV}::$REPONAME

########################################
