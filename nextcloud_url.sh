#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Change url, e.g. path from /owncloud to /
#

dash # bash interprets tabs which causes problems with patch
cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/conf-available/owncloud.conf.orig	2016-05-03 17:52:38.000000000 +0200
+++ /etc/apache2/conf-available/owncloud.conf	2016-06-28 13:38:35.972000000 +0200
@@ -1,4 +1,4 @@
-Alias /owncloud "/var/www/owncloud/"
+Alias / "/var/www/owncloud/"
 <Directory "/var/www/owncloud">
   Options +FollowSymLinks
   AllowOverride All

EOF
exit

vi /var/www/owncloud/config/config.php
# Add 
#  'htaccess.RewriteBase' => '/',
#
# Change
#   'overwrite.cli.url' => 'https://cloud.tree.h-brs.de/owncloud',
# to
#   'overwrite.cli.url' => 'https://cloud.tree.h-brs.de/'

(cd /var/www/owncloud/ && sudo -u www-data php occ maintenance:update:htaccess)

exit # the end
