#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# LDAP Utilities
#

apt install ldap-utils

# List directory entries
ldapsearch -x -b "dc=fh-bonn-rhein-sieg,dc=de" -H ldap://ldap.inf.h-brs.de

# List directory entries with filter
ldapsearch -x -b "dc=fh-bonn-rhein-sieg,dc=de" -H ldap://ldap.inf.h-brs.de uid=* uid

# Find out DN of user jmeng2m
ldapsearch -x -b "dc=fh-bonn-rhein-sieg,dc=de" -H ldap://ldap.inf.h-brs.de -LLL uid=jmeng2s dn
ldapsearch -x -b "dc=fh-bonn-rhein-sieg,dc=de" -H ldap://ldap.inf.h-brs.de -LLL uid=jmeng2m dn

# Use DN to connect to LDAP server, bind to LDAP directory using DN and perform whoami operation
# NOTE: Password is submitted in clear-text to LDAP server, so make sure to use transport level security!
ldapwhoami -H ldap://ldap.inf.h-brs.de -D "uid=jmeng2s,ou=students,dc=fb02,dc=fh-bonn-rhein-sieg,dc=de" -x -W
ldapwhoami -H ldap://ldap.inf.h-brs.de -D "uid=jmeng2m,ou=staff,dc=fb02,dc=fh-bonn-rhein-sieg,dc=de" -x -W

# Change password
# NOTE: Passwords are submitted in clear-text to LDAP server, so make sure to use transport level security!
ldappasswd -H ldap://ldap.inf.h-brs.de -D "uid=jmeng2s,ou=students,dc=fb02,dc=fh-bonn-rhein-sieg,dc=de" -x -W -S
ldappasswd -H ldap://ldap.inf.h-brs.de -D "uid=jmeng2m,ou=staff,dc=fb02,dc=fh-bonn-rhein-sieg,dc=de" -x -W -S

# An error message "Result: Insufficient access (50)" indicates that the system on which ldappasswd is executed, might
# not be authorized to modify passwords.

# The Computer Science Department of University of Applied Sciences Bonn-Rhein-Sieg does allow password changes only
# from systems under control of the admin team, e.g. home.inf.h-brs.de, pool computers and admin vpn:
#
#  olcAccess: {3}to attrs=userPassword  by anonymous auth
#   by self read break
#   by * none
#  olcAccess: {4}to attrs=userPassword
#   by peername.ip="127.0.0.1" write
#   by peername.ip="10.20.100.0%255.255.255.0" write
#   by peername.ip="10.20.10.0%255.255.255.0" write
#   by peername.ip="10.20.8.0%255.255.255.192" write
#   by peername.ip="194.95.66.20" write
#   by self read
#
# Reason for that is that some systems used "replace: userPassword" to store clear-text passwords or using
# incompatible hash functions instead of using the official LDAP extension for changing passwords.
