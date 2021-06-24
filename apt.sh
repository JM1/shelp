#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# apt package management
#

####################
# Show suggests/recommmends for all packages installed
# Ref.: https://askubuntu.com/questions/244470/list-all-suggested-packages-for-currently-installed-packages

dpkg-query -W -f='${Package} (status: ${Status}) suggests: ${Suggests}\n' \
  | grep 'status: install ok installed' | grep -v 'suggests: $'

aptitude search '?reverse-suggests(~i)!(~i)'
aptitude search '?reverse-recommends(~i)!(~i)'

(LANG=C && for pkg in $(dpkg -l | awk '{ print $2 }' | xargs echo); do apt-cache depends $pkg 2>/dev/null | awk '/Recommends:/ {print $2}'; done) | sort | uniq

####################
# List of obsolete packages

aptitude search '~o'
apt-show-versions | grep 'No available version'

####################
# List pending, old and obsolete configuration files

find /etc -iname '*.ucftmp*' -o -iname '*.dpkg-*' -o -iname '*.ucf-*' -o -name '*.merge-error' | sort | uniq

####################
# List all packages with rc status a.k.a. package removed but config files left
aptitude search '~c' | awk '{print $2}'
dpkg -l | grep '^rc\b' | awk '{print $2}'

# List all libraries with rc status
aptitude search '?and(?section(libs), ~c)' | awk '{print $2}'

# Only purge packages with rc status, that don't have a postrm script (and hence do nothing)
for i in $(dpkg --list | awk '{if ($1 == "rc") {print $2}}'); do [ ! -f /var/lib/dpkg/info/$i.postrm ] && echo $i; done | xargs apt-get purge -y

# Only purge libraries with rc status
aptitude search '?and(?section(libs), ~c)' | awk '{print $2}' | xargs aptitude purge -y

# Purge old config files belonging to packages which were removed
dpkg -l | grep '^rc\b' | awk '{print $2}' | xargs sudo aptitude purge -y

####################
# aptitude
# Ref.: http://algebraicthunk.net/~dburrows/projects/aptitude/doc/en/ch02s03s05.html

# Filter packages view
#
# 1. Press F10, goto Views, choose New Flat Package List
# 2. Press l (lower L) to limit display
# 3. Enter filter, e.g. to
#    a) select manually installed packages and all packages that are selected for install:
#       ~i ?not(~M) | ~ainstall
#    b) select packages that were removed but not purged:
#       ~c

# Show manually installed packages
aptitude -F "%p" search "~i ?not(~M)"
# Show manually installed packages with version numbers
aptitude -F "%p %v" search "~i ?not(~M)"
# Show automatically installed packages
aptitude -F "%p" search "~M"
# Show automatically installed packages with version numbers
aptitude -F "%p %v" search "~M"

# Sort and save package lists
aptitude -F "%p %v" search "~i ?not(~M)" | sort >> "$(hostname).manual.packages.$(date +%Y%m%d%H%M%S).list"
aptitude -F "%p %v" search "~M"  | sort >> "$(hostname).auto.packages.$(date +%Y%m%d%H%M%S).list"

####################
# Compare packages installed on different hosts

aptitude -F "%p %v" search "~i ?not(~M)" | sort >> $(hostname).manual.packages.$(date +%Y%m%d%H%M%S).list && \
aptitude -F "%p %v" search "~M"  | sort >> $(hostname).auto.packages.$(date +%Y%m%d%H%M%S).list

HOST=$(hostname)
ssh $HOST 'aptitude -F "%p %v" search "~i ?not(~M)"' | sort >> "$HOST.manual.packages.$(date +%Y%m%d%H%M%S).list" && \
ssh $HOST 'aptitude -F "%p %v" search "~M"' | sort >> "$HOST.auto.packages.$(date +%Y%m%d%H%M%S).list"

####################
#
# Various package manager commands
#

apt-get install [...]
aptitude
aptitude install [...]
apt-setup
apt-get clean
dpkg-reconfigure [xdm/gdm/kde/xserver-xfree86]

aptitude remove --purge openoffice-de-en
aptitude remove --purge ttf-openoffice

####################
# Turn off incremental (pdiff) package updates
# Ref.: https://www.blackmanticore.com/87f3032e60abc009ec1f6af0f924f158

# if 
#  apt-get update
# fails with e.g. 
#  E: Failed to fetch http://deb.debian.org/debian/dists/stretch-backports/non-free/binary-amd64/PackagesIndex  Couldn't parse pdiff index
#  E: Some index files failed to download. They have been ignored, or old ones used instead.
# or
#  E: Could not open file /var/lib/apt/lists/..._Packages.diff_Index - open (2: No such file or directory)
# then try
apt-get update -o Acquire::Pdiffs=false

####################
