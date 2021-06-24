#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Package Build with pbuilder
#
# ATTENTION:
# The following options have been set in /root/.pbuilderrc and don't have be set here:
#  --buildplace /tmp/pbuilder-build
#  --hookdir /etc/pbuilder/hookdir/
#  --buildresult /var/cache/pbuilder/result/$(date +%Y%m%d%H%M%S)

pbuilder create --distribution wheezy --debootstrapopts --variant=buildd
pbuilder update

apt-get source calibre
pbuilder build   --debbuildopts "-j4" *.dsc
#See /var/cache/pbuilder/result/

#Alternative:
pbuilder update --basetgz /var/cache/pbuilder/base-compiz.tgz
pbuilder build --debbuildopts "-j4" --basetgz /var/cache/pbuilder/base-compiz.tgz *.dsc

#Log into pbuilder: 
pbuilder --login --save-after-login  


# Package Build with pbuilder for Ubuntu (native architecture)
DIST=raring pbuilder create --debootstrapopts --variant=buildd
DIST=raring pbuilder update  
DIST=raring pbuilder --login --save-after-login  
DIST=raring pbuilder build  --debbuildopts "-j4" *.dsc
DIST=raring pbuilder build  --debbuildopts "-j4" --twice *.dsc

DIST=saucy pbuilder create --debootstrapopts --variant=buildd
DIST=saucy pbuilder update  
DIST=saucy pbuilder build --debbuildopts "-j4" *.dsc

# Package Build with pbuilder for Ubuntu (i386)
DIST=raring ARCH=i386 pbuilder create --debootstrapopts --variant=buildd
DIST=raring ARCH=i386 pbuilder update  
DIST=raring ARCH=i386 pbuilder build --debbuildopts "-j4" *.dsc

DIST=saucy ARCH=i386 pbuilder create --debootstrapopts --variant=buildd
DIST=saucy ARCH=i386 pbuilder update  
DIST=saucy ARCH=i386 pbuilder build --debbuildopts "-j4" *.dsc

# Package Build with pbuilder for Debian 8 (Jessie)
DIST=jessie pbuilder create
DIST=jessie pbuilder update
DIST=jessie pbuilder build --debbuildopts "-j4" *.dsc

# Package Build with pbuilder for Debian 9 (Stretch)
DIST=stretch pbuilder create --debootstrapopts --variant=buildd
DIST=stretch pbuilder update
DIST=stretch pbuilder build --debbuildopts "-j4" *.dsc

# Execute command for all architectures and distributions
PB_CMD='pbuilder build --debbuildopts "-j4" *.dsc'
for dist in saucy jessie trusty; do \
 for arch in amd64 i386; do \
  DIST=$dist ARCH=$arch $PB_CMD; \
 done; \
done
