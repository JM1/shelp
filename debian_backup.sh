#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Configuration backup
#

# backup files and compare to existing systems
for dir in etc keys; do
    [ -d /$dir/ ] && tar \
        --create \
        --verbose \
        --preserve-permissions --acls --xattrs --selinux \
        --one-file-system \
        --use-compress-program=bzip2 \
        --sparse \
        --file "/tmp/$(hostname)_${dir}_$(date +%Y%m%d%H%M%S).tar.bz2" \
        --exclude etc/udev/hwdb.bin \
        --directory=/ \
        $dir/
done

# More examples in /etc/cron.daily/sys_backup

aptitude -F "%p %v" search "~i ?not(~M)" | sort >> "$(hostname).manual.packages.$(date +%Y%m%d%H%M%S).list" && \
aptitude -F "%p %v" search "~M"  | sort >> "$(hostname).auto.packages.$(date +%Y%m%d%H%M%S).list"
