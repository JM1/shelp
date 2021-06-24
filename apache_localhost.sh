#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Bind Apache2 to localhost / Listen to localhost only
#

cp -raiv /etc/apache2/ports.conf /etc/apache2/ports.conf.orig

dash # bash interprets tabs which causes problems with patch

cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/ports.conf.orig	2015-10-24 10:37:19.000000000 +0200
+++ /etc/apache2/ports.conf	2016-06-27 16:44:50.776000000 +0200
@@ -2,14 +2,14 @@
 # have to change the VirtualHost statement in
 # /etc/apache2/sites-enabled/000-default.conf
 
-Listen 80
+Listen localhost:80
 
 <IfModule ssl_module>
-	Listen 443
+	Listen localhost:443
 </IfModule>
 
 <IfModule mod_gnutls.c>
-	Listen 443
+	Listen localhost:443
 </IfModule>
 
 # vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF

exit

service apache2 restart
