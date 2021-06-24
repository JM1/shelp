#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# LDAP Authentication
#
# References:
# [1] https://www.redhat.com/en/blog/overview-direct-integration-options
# [2] https://wiki.ubuntu.com/Enterprise/Authentication
# [3] https://www.redhat.com/en/blog/sssd-vs-winbind
#
# NOTE: Authentication is just one part of directory integration, others are
#       e.g. identity and policy management, file and printer sharing, ... [1].
#       See chapter "(Active) Directory Integration" above.

# Possible authentication choices are [1][2]:
# a. (plain) LDAP (using libpam-ldapd/libpam-ldap, optionally including cached credentials with nss-updatedb and pam-ccreds)
# b. LDAP (as in a.) plus Kerberos
# c. winbind3/winbind4 (Samba)
# d. SSSD (System Security Services Daemon)
#
# NOTE: SSSD and winbind are the most complete and powerful solutions, with sssd being the latest and up-to-date approach [1].

# Comparison of SSSD vs. winbind in [1] and [3]

########################################
#
# LDAP Authentication using libpam-ldapd
# "identity and authentication management with an LDAP server on unix systems" [5]
#
# References:
# [1] https://wiki.debian.org/LDAP/NSS
# [2] https://arthurdejong.org/nss-pam-ldapd/setup
# [3] http://people.skolelinux.org/pere/blog/Caching_password__user_and_group_on_a_roaming_Debian_laptop.html
# [4] https://serverfault.com/questions/284307/libpam-ldap-or-libpam-ldapd/284348#284348
# [5] https://arthurdejong.org/nss-pam-ldapd/
# [6] https://manpages.debian.org/stretch/libldap-common/ldap.conf.5.en.html
# [7] https://www.redhat.com/en/blog/overview-direct-integration-options
# 
# NOTE: libpam-ldapd is preferred to libpam-ldap! For libpam-ldapd vs. libpam-ldap see [4] and [5].
# NOTE: SSSD (System Security Services Daemon) is a modern and more powerful alternative to libpam-ldapd and libpam-ldap, see [7] and above!

# Overview:
#  directory lookup and password checking is done using libnss-ldapd and libpam-ldapd
#  password caching is provided by libpam-ccreds
#  directory caching is done by nscd
#  local user with home directory in /home/ is created by libpam-mklocaluser package
# Ref.: [3]

# Guide [1], [2] and [3]

# NOTE: File /etc/ldap/ldap.conf is from libpam-ldap and thus not for use with libpam-ldapd [6], 
# with libpam-ldapd instead most of the configuration for common setups is performed during installation [1].

########################################
#
# LDAP Authentication using libpam-ldap
# (tested on Ubuntu Server 14.04 LTS within Fachbereichs Informatik of Hochschule Bonn-Rhein-Sieg)
#
# NOTE: libpam-ldapd is preferred over libpam-ldap, see above!
#
# Ref.:
#  https://wiki.debian.org/LDAP/PAM
#  https://ux-2s18.inf.h-brs.de/faq/informationen-fuer-labore/nutzen-der-ldap-benutzerdatenbank

apt-get install libpam-ldap
# Bei der Installation werden fünf Abfragen [hier als a. bis e. bezeichnet] an den Benutzer gestellt. Die Eingaben lauten wie folgt:
# a. ldaps://ldap.inf.h-brs.de
# b. dc=fh-bonn-rhein-sieg,dc=de
# c. 3
# d. no
# e. no

vi /etc/ldap.conf
# Die Direktive "bind_policy soft" setzen.
# Ggfs. ist auch das Aktivieren der Verschlüsselung sinnvoll (STARTTLS), siehe hierzu das unten zitierte Debian-Wiki.

vi /etc/nsswitch.conf

# Folgende Änderungen vornehmen:
#  passwd: compat nis ldap
#   group: compat nis
#  shadow: compat ldap
# 
# Stattdessen Ggfs. auch:
#  passwd: compat ldap
#   group: compat ldap
#  shadow: compat ldap

# Automatisches Erstellen von Home-Verzeichnissen aktivieren:
# Am Ende der Datei '/etc/pam.d/common-session' die folgenden Zeilen eintragen:
#
#  session     required      pam_mkhomedir.so skel=/etc/skel umask=0022
#
# NOTE: Das Modul 'pam_mkhomedir.so' ist Teil des Debian-Pakets libpam-modules.

# NOTE:
# The ldap client should verify the server certificate upon connection if "TLS_REQCERT hard" is set in
# /etc/ldap/ldap.conf [1][2], which is the default [3]. But at least on Ubuntu 14.04 with a self-signed server
# certificate at FB02 H-BRS which is not known to the ldap client the certificate is accepted. Why??
#
# Ref.:
# [1] https://serverfault.com/a/250387/373320
# [2] https://help.ubuntu.com/community/SecuringOpenLDAPConnections#Configure_LDAP_Client
# [3] https://manpages.debian.org/stretch/libldap-common/ldap.conf.5.en.html

########################################

exit # the end
