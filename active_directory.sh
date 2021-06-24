#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# (Active) Directory Integration
#
# References:
# [1] https://www.redhat.com/en/blog/overview-direct-integration-options
# [2] http://www.burkhard-obergoeker.de/linux2012/index.php/know-how/24-sssd-ad

# Directory integration consists of e.g.:
# a. Authentication (LDAP)
# b. Single Sign On (Kerberos)
# c. Identity Lookup and Mapping
# d. Policy Management (sudo, hbac, automount, selinux, ...)
# e. File and Printer Sharing (Samba)
# ...

# One way of directory integration is a setup utilizing [2]:
#  - samba
#  - krb5, pam_krb5
#  - sssd sssd-ad sssd-tools
#  - cifs_mount (smbfs)
#  - pam_mount
