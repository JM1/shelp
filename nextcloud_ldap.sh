#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enable LDAP authentication in Nextcloud or ownCloud
#
apt-get install php5-ldap

# When using LDAP authentication you have to define a new ldap group containing only allowed users.
# This causes additional administration overhead, e.g. for each new users the ldap admin has to add 
# that new user to the ldap group.
#
# Setup LDAP authentication as described here:
#  https://doc.owncloud.org/server/9.0/admin_manual/configuration_user/user_auth_ldap.html
#
#  Host: ldaps://ldap.inf.fh-bonn-rhein-sieg.de
#  Port: 389 ? 636 ? 3269
#  User DN and Password are empty.
#  Base DN: dc=fh-bonn-rhein-sieg,dc=de
