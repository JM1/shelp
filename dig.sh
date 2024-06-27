#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# dig
#

####################
# Check DNS records with dig
# Ref.:
# https://manpages.debian.org/unstable/bind9-dnsutils/dig.1.en.html

# Test name resolution for www.google.de via dns server 10.10.0.166
# Ref.: https://www.linux.com/learn/check-your-dns-records-dig
dig +short @10.10.0.166 NS www.google.de

# Do simplified reverse lookup, mapping ip address to DNS name, for ip address 10.6.44.10 at DNS server 10.38.5.26
dig @10.38.5.26 -x 10.6.44.10

# Enumerate all dns names for given ip range
# Ref.: https://linuxcommando.blogspot.com/2008/07/how-to-do-reverse-dns-lookup.html
for i in $(seq 1 254); do dig +noall +answer -x 10.20.130.$i; done

####################
