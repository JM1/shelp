#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup Apache2 on Debian 8 (Jessie)
#

apt-get install apache2 apache2-doc apache2-utils haveged

cp -raiv /etc/apache2/conf-available/security.conf /etc/apache2/conf-available/security.conf.orig

dash # bash interprets tabs which causes problems with patch
cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/conf-available/security.conf.orig	2015-11-28 13:59:22.000000000 +0100
+++ /etc/apache2/conf-available/security.conf	2016-06-28 10:03:56.980000000 +0200
@@ -23,8 +23,9 @@
 # Set to one of:  Full | OS | Minimal | Minor | Major | Prod
 # where Full conveys the most information, and Prod the least.
 #ServerTokens Minimal
-ServerTokens OS
+#ServerTokens OS
 #ServerTokens Full
+ServerTokens Prod
 
 #
 # Optionally add a line containing the server version and virtual host
@@ -34,7 +35,7 @@
 # Set to "EMail" to also include a mailto: link to the ServerAdmin.
 # Set to one of:  On | Off | EMail
 #ServerSignature Off
-ServerSignature On
+ServerSignature Off
 
 #
 # Allow TRACE method

EOF
exit

a2dissite 000-default

# Enable your modules, sites and configurations with
a2enmod ...
a2ensite ...
a2enconf ...

service apache2 restart

# NOTE: For optimal performance setup php-fpm and libapache2-mod-fcgid as described in apache_php-fpm.sh

exit # the end

# TODO: Find replacement modules for old (pre-Jessie) debian packages
#        - libapache2-mod-auth-mysql
#        - libapache2-mod-auth-pam, e.g. see http://ubuntuforums.org/showthread.php?t=1330542&p=8658462#post8658462
#        - libapache2-mod-gnutls
