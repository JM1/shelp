#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Mitigate Denial-of-service attacks using mod-evasive for Apache2
#

apt-get install libapache2-mod-evasive

cp -raiv /etc/apache2/mods-available/evasive.conf /etc/apache2/mods-available/evasive.conf.orig

mkdir /var/log/mod_evasive

dash # bash interprets tabs which causes problems with patch
cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/mods-available/evasive.conf.orig	2014-05-20 10:35:52.000000000 +0200
+++ /etc/apache2/mods-available/evasive.conf	2016-06-28 11:10:39.260000000 +0200
@@ -1,12 +1,12 @@
 <IfModule mod_evasive20.c>
-    #DOSHashTableSize    3097
-    #DOSPageCount        2
-    #DOSSiteCount        50
-    #DOSPageInterval     1
-    #DOSSiteInterval     1
-    #DOSBlockingPeriod   10
+    DOSHashTableSize    3097
+    DOSPageCount        2
+    DOSSiteCount        50
+    DOSPageInterval     1
+    DOSSiteInterval     1
+    DOSBlockingPeriod   10
 
-    #DOSEmailNotify      you@yourdomain.com
+    DOSEmailNotify      jakob.meng@h-brs.de
     #DOSSystemCommand    "su - someuser -c '/sbin/... %s ...'"
-    #DOSLogDir           "/var/log/mod_evasive"
+    DOSLogDir           "/var/log/mod_evasive"
 </IfModule>
EOF
exit

a2enmod evasive

service apache2 restart

# TODO: Why does not evasive send any mails when dos has been detected?
