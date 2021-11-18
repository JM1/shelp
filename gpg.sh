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
# is trickier since gpg doesn't know what sort of message it is
# (public key, encrypted or signed message, a detached signature ...)
gpg --enarmor < the-gpg-file.gpg > the-asc-file.asc
# now edit the file and e.g. change "ARMORED FILE" to "PUBLIC KEY BLOCK" at the top and at the end
sed -i 's/ARMORED FILE/PUBLIC KEY BLOCK/g' the-asc-file.asc

# receive key and store in keyring
gpg --keyserver wwwkeys.eu.pgp.net --recv-keys A70DAF536070D3A1

# create checksums and sign checksums file
sha256sum * > SHA256SUMS
gpg --detach-sign --armor SHA256SUMS

# verify signature and checksums
gpg --verify SHA256SUMS.asc
sha256sum -c SHA256SUMS

# export ascii armored version of the public key
gpg --output public.pgp --armor --export username@email

# export ascii armored version of the secret key
gpg --output private.pgp --armor --export-secret-key username@email

# "For most use cases, the secret key need not be exported and should not distributed.
#  If the purpose is to create a backup key, you should use the backup option. This
#  will export all necessary information to restore the secrets keys including the
#  trust database information. Make sure you store any backup secret keys off the
#  computing platform and in a secure physical location."
# Ref.: https://newbedev.com/how-to-export-a-gpg-private-key-and-public-key-to-a-file
gpg --output backupkeys.pgp --armor --export-secret-keys --export-options export-backup user@email
