#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Change hostname
#

# NOTE: A quote from RFC 1178 - Choosing a Name for Your Computer:
#       "Don't expect case to be preserved.
#
#        Upper and lowercase characters look the same to a great deal of internet software,
#        often under the assumption that it is doing you a favor. It may seem appropriate
#        to capitalize a name the same way you might do it in English, but convention 
#        dictates that computer names appear all lowercase. (And it saves holding down the
#        shift key.)" [1]
#
# NOTE: "The Internet standards (Requests for Comments) for protocols specify that labels
#        may contain only the ASCII letters a through z (in a case-insensitive manner),
#        the digits 0 through 9, and the hyphen-minus character ('-'). The original
#        specification of hostnames in RFC 952 disallowed labels from starting with a digit
#        or with a hyphen character, and could not end with a hyphen. However, a subsequent
#        specification (RFC 1123) permitted hostname labels to start with digits. No other
#        symbols, punctuation characters, or white space are permitted. Internationalized
#        domain names are stored in the Domain Name System as ASCII strings using Punycode
#        transcription." [2]
#
# NOTE: "Ensures that each segment
#        - Contains at least one character and a maximum of 63 characters
#        - Consists only of allowed characters: letters (A-Z and a-z),
#          digits (0-9), and hyphen (-)
#        - Ensures that the final segment (representing the top level domain
#          name) contains at least one non-numeric character
#        - Does not begin or end with a hyphen
#        - maximum total length of 253 characters
#        For more details , please see: http://tools.ietf.org/html/rfc1035,
#        https://www.ietf.org/rfc/rfc1912, and
#        https://tools.ietf.org/html/rfc1123" [6]

# Ref.:
# [1] https://tools.ietf.org/html/rfc1178
# [2] https://en.wikipedia.org/wiki/Hostname
# [3] https://serverfault.com/questions/539922/case-sensitive-hostnames
# [4] https://serverfault.com/questions/261341/is-the-hostname-case-sensitive
# [5] https://serverfault.com/questions/672984/is-the-hostname-part-of-https-urls-truly-case-insensitive/672990#672990
# [6] https://github.com/openstack/oslo.config/blob/6e91dbb2d590fc1706243922c0ed71f6c2fcdf73/oslo_config/types.py#L772

# Find other occurrences of previous hostname
grep -r -i "$(hostname)" /etc/

vi /etc/hostname
vi /etc/hosts
vi /etc/mailname

vi /etc/default/grub
update-grub

vi /etc/dovecot/local.conf
systemctl restart dovecot.service

# Change /etc/exim4/update-exim4.conf.conf with
dpkg-reconfigure exim4-config
systemctl restart exim4.service

# Renew certificates, e.g. as described in "Let’s Encrypt"."Renew certificate for changed hostname"

vi ~/.bash*
# Update Thunderbird accounts and filters

reboot

exit # the end
