#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# APT key management
#
####################
# show/list installed apt keys
#
# the short key id is no longer shown when you use the list command, but it is actually the last 8 characters of the long hex
# Ref.: https://askubuntu.com/a/846877/836620
apt-key list

####################
# Receive and import gpg keys for apt repositories
#
# References:
#  man apt-key fingerprint

# TODO: Incorporate https://blog.jak-linux.org/2021/06/20/migrating-away-apt-key/

# On Debian 10 (Buster)
#
# NOTE:
#  "
#   apt-key supports only the binary OpenPGP format (also known as "GPG key public ring") in
#   files with the "gpg" extension, not the keybox database format introduced in newer gpg(1)
#   versions as default for keyring files. Binary keyring files intended to be used with any
#   apt version should therefore always be created with gpg --export.
#   
#   Alternatively, if all systems which should be using the created keyring have at least apt
#   version >= 1.4 installed, you can use the ASCII armored format with the "asc" extension
#   instead which can be created with gpg --armor --export.
#  "
#  Ref.: man apt-key fingerprint

wget 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0893DC134548A28D' -O the-asc-file.asc
vi the-asc-file.asc # remove html
gpg --dearmor < the-asc-file.asc > the-gpg-file.gpg
cp -raiv the-gpg-file.gpg /etc/apt/trusted.gpg.d/
apt-get update

# On Debian 8 (Jessie) or older
gpg --keyserver wwwkeys.eu.pgp.net --recv-keys A70DAF536070D3A1
gpg --export A70DAF536070D3A1 | apt-key add -
apt-get update
# or
wget http://pfad/zum/key.gpg -O- | apt-key add -
apt-get update

####################
