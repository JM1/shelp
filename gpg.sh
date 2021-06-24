#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# GPG

# Examine/Inspect a key file
# References: 
#  https://lists.gnupg.org/pipermail/gnupg-users/2010-November/039882.html
#  https://stackoverflow.com/a/22147722
gpg -v < pubkey.asc

# convert from ascii (*.asc) to binary (*.gpg)
# References: 
#  https://lists.gnupg.org/pipermail/gnupg-devel/2011-October/026252.html
#  https://superuser.com/a/401597
gpg --dearmor the-asc-file.asc
gpg --dearmor < the-asc-file.asc > the-gpg-file.gpg

# convert from binary (*.gpg) to ascii (*.asc)
# is trickier since gpg doesn't know what sort of message it is (public key, encrypted or signed message, a detached signature ...)
gpg --enarmor < the-gpg-file.gpg > the-asc-file.asc
# now edit the file and change "ARMORED FILE" to e.g. "PUBLIC KEY BLOCK" at the top and at the end
sed -i 's/ARMORED FILE/PUBLIC KEY BLOCK/g' the-asc-file.asc

# receive key and store in keyring
gpg --keyserver wwwkeys.eu.pgp.net --recv-keys A70DAF536070D3A1

# create checksums and sign checksums file
sha256sum * > SHA256SUMS
gpg --detach-sign --armor SHA256SUMS

# verify signature and checksums
gpg --verify SHA256SUMS.asc
sha256sum -c SHA256SUMS
