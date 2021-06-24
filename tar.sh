#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
# Zip files with tar and gzip
tar czvf ARCHIV.tar.gz FILE1 DIR1/ FILE2 DIR2/ ...

########################################
#
# tar with pbzip2
#
# pbzip2 provides much faster compression than 7z
#
# Ref.:
#  http://debianforum.de/forum/viewtopic.php?f=29&t=95300&hilit=pbzip2#p821766
#  man pbzip2

tar --verbose --create --use-compress-program=pbzip2 --file OUTPUT.tar.bzip2  INPUT...
# or
tar --verbose --create                               --file OUTPUT.tar.pbzip2 INPUT...

########################################
#
# tar | 7z
#

SZA_DEFAULT_PARAMS_WITH_COMPRESSION="-bd -t7z -m0=lzma2 -mmt=4 -mx5 -ms=on" #Normal Compression
SZA_DEFAULT_PARAMS_WITHOUT_COMPRESSION="-bd -t7z -mx0" #Without Compression

#eval time bsdtar \
eval time tar \
  --preserve-permissions --acls --xattrs --selinux \
  --one-file-system \
  -cf - /folder | eval 7za a -si \
    -mhe=on -p \
    $SZA_DEFAULT_PARAMS_WITHOUT_COMPRESSION \
    "/tmp/output_$(date +%Y%m%d%H%M%S).tar.7z"

7za x -so FILENAME.tar.7z | bsdtar --numeric-owner --preserve-permissions --same-owner -xf -

# examples
cd /home && time tar --preserve-permissions --acls --xattrs --selinux --one-file-system -cvf /backups/$(hostname)_home_$(date +%Y%m%d%H%M%S).tar johnwayne/

########################################
#
# Clone folders or whole filesystem via SSH
#

ssh johnwayne@saloon.wildwildwest.com 'tar c --one-file-system --acls --xz -v -f - /' | \
    cat > "files_backup_$(date +%Y%m%d%H%M%S).tar.xz"

########################################
