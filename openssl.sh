#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# OpenSSL
#
####################
# Install local or self-signed CA certificates
#
# References:
# [1] /usr/share/doc/ca-certificates/README.Debian
# [2] https://askubuntu.com/questions/73287/how-do-i-install-a-root-certificate

# NOTE: Some web browsers, email clients, and other software that use SSL maintain their
#       own CA trust database and may not use the trusted CA certificates in this package.

mkdir /usr/local/share/ca-certificates/

# Convert certificate to PEM format with *.crt ending
openssl x509 -in foo.pem -inform PEM -outform PEM -out foo.crt

# Copy PEM certificates as single files ending with ".crt" into /usr/local/share/ca-certificates/
update-ca-certificates

# For removal run
update-ca-certificates --fresh

####################
# Show certificate info like certificate chain
openssl s_client -showcerts -connect imap.1und1.de:993

openssl x509 -in MY_LOCAL_CERT.pem -text

####################
# Show certificate fingerprint
# Ref.:
#  man openssl-x509
openssl x509 -sha256 -in *.pem -noout -fingerprint

####################
# Remove password from *.p12 files

CERT="vpncertWS20112012"
openssl pkcs12 -in "$CERT.p12" -out "$CERT.nophrase.pem" -nodes
openssl pkcs12 -export -in "$CERT.nophrase.pem" -out "$CERT.nophrase.p12" -nodes
openssl pkcs12 -in "$CERT.nophrase.p12" -info -noout

####################
