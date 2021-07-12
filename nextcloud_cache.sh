#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Nextcloud Memory Caching configuration
#
# NOTE: For multi-server installations you should additionally install Redis,
#       see https://doc.owncloud.org/server/9.0/admin_manual/configuration_server/caching_configuration.html
#
# Ref.:
#  https://docs.nextcloud.com/server/14/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
#  https://docs.nextcloud.com/server/15/admin_manual/configuration_server/caching_configuration.html
#  https://dasnetzundich.de/redis-caching-richtig-einstellen-fuer-nextcloud/

####################
# Enable Zend OPCache

# probably not neccessary because opcache should be installed by default
apt-get install php-opcache
phpenmod opcache

# On Debian 9 (Stretch)
cat << 'EOF' | patch -p0 -d /
--- /etc/php/7.0/apache2/php.ini.orig   2018-06-14 15:50:25.000000000 +0200
+++ /etc/php/7.0/apache2/php.ini        2019-02-17 08:18:00.557326666 +0100
@@ -1765,19 +1765,24 @@
 [opcache]
 ; Determines if Zend OPCache is enabled
 ;opcache.enable=0
+opcache.enable=1
 
 ; Determines if Zend OPCache is enabled for the CLI version of PHP
 ;opcache.enable_cli=0
+opcache.enable_cli=1
 
 ; The OPcache shared memory storage size.
 ;opcache.memory_consumption=64
+opcache.memory_consumption=128
 
 ; The amount of memory for interned strings in Mbytes.
 ;opcache.interned_strings_buffer=4
+opcache.interned_strings_buffer=8
 
 ; The maximum number of keys (scripts) in the OPcache hash table.
 ; Only numbers between 200 and 1000000 are allowed.
 ;opcache.max_accelerated_files=2000
+opcache.max_accelerated_files=10000
 
 ; The maximum percentage of "wasted" memory until a restart is scheduled.
 ;opcache.max_wasted_percentage=5
@@ -1796,6 +1801,7 @@
 ; memory storage allocation. ("1" means validate once per second, but only
 ; once per request. "0" means always validate)
 ;opcache.revalidate_freq=2
+opcache.revalidate_freq=1
 
 ; Enables or disables file search in include_path optimization
 ;opcache.revalidate_path=0
EOF
service apache2 restart

# On Debian 10 (Buster)
true # noop

# On Debian 9 (Stretch)
cat << 'EOF' | patch -p0 -d /
--- /etc/php/7.0/fpm/php.ini.orig   2018-06-14 15:50:25.000000000 +0200
+++ /etc/php/7.0/fpm/php.ini        2019-02-17 08:18:00.557326666 +0100
@@ -1765,19 +1765,24 @@
 [opcache]
 ; Determines if Zend OPCache is enabled
 ;opcache.enable=0
+opcache.enable=1
 
 ; Determines if Zend OPCache is enabled for the CLI version of PHP
 ;opcache.enable_cli=0
+opcache.enable_cli=1
 
 ; The OPcache shared memory storage size.
 ;opcache.memory_consumption=64
+opcache.memory_consumption=128
 
 ; The amount of memory for interned strings in Mbytes.
 ;opcache.interned_strings_buffer=4
+opcache.interned_strings_buffer=8
 
 ; The maximum number of keys (scripts) in the OPcache hash table.
 ; Only numbers between 200 and 1000000 are allowed.
 ;opcache.max_accelerated_files=2000
+opcache.max_accelerated_files=10000
 
 ; The maximum percentage of "wasted" memory until a restart is scheduled.
 ;opcache.max_wasted_percentage=5
@@ -1796,6 +1801,7 @@
 ; memory storage allocation. ("1" means validate once per second, but only
 ; once per request. "0" means always validate)
 ;opcache.revalidate_freq=2
+opcache.revalidate_freq=1
 
 ; Enables or disables file search in include_path optimization
 ;opcache.revalidate_path=0
EOF
systemctl restart php7.0-fpm.service

# On Debian 10 (Buster)
true # noop

# On Debian 9 (Stretch)
cat << 'EOF' | patch -p0 -d /
--- /etc/php/7.0/cli/php.ini.orig   2018-06-14 15:50:25.000000000 +0200
+++ /etc/php/7.0/cli/php.ini        2019-02-17 08:18:00.557326666 +0100
@@ -1765,19 +1765,24 @@
 [opcache]
 ; Determines if Zend OPCache is enabled
 ;opcache.enable=0
+opcache.enable=1
 
 ; Determines if Zend OPCache is enabled for the CLI version of PHP
 ;opcache.enable_cli=0
+opcache.enable_cli=1
 
 ; The OPcache shared memory storage size.
 ;opcache.memory_consumption=64
+opcache.memory_consumption=128
 
 ; The amount of memory for interned strings in Mbytes.
 ;opcache.interned_strings_buffer=4
+opcache.interned_strings_buffer=8
 
 ; The maximum number of keys (scripts) in the OPcache hash table.
 ; Only numbers between 200 and 1000000 are allowed.
 ;opcache.max_accelerated_files=2000
+opcache.max_accelerated_files=10000
 
 ; The maximum percentage of "wasted" memory until a restart is scheduled.
 ;opcache.max_wasted_percentage=5
@@ -1796,6 +1801,7 @@
 ; memory storage allocation. ("1" means validate once per second, but only
 ; once per request. "0" means always validate)
 ;opcache.revalidate_freq=2
+opcache.revalidate_freq=1
 
 ; Enables or disables file search in include_path optimization
 ;opcache.revalidate_path=0
EOF

# On Debian 10 (Buster)
true # noop

####################
# Enable APCu

# Debian 8 (Jessie)
apt-get install php5-apcu

# Debian 9 (Stretch) or later
apt-get install php-apcu

vi /var/www/owncloud/config/config.php
# Add the line
#  'memcache.local' => '\OC\Memcache\APCu',
# to '$CONFIG = array (...)'

# Nextcloud 21 or later
# Ref.: https://linuxnews.de/2021/07/nextcloud-22-deaktiviert-php-cronjobs/
cat << 'EOF' > "$(ls -d -1 /etc/php/7.* | tail -n 1)/cli/conf.d/99-apc-enable-cli.ini"
; 2021 Jakob Meng, <jakobmeng@web.de>
; Enable APCu on CLI to e.g. fix issues with Nextcloud’s cron jobs
; Ref.: https://docs.nextcloud.com/server/21/admin_manual/configuration_server/caching_configuration.html

apc.enable_cli = 1
EOF

service apache2 restart

####################
# Enable Redis
apt-get install redis-server php-redis

cat << 'EOF' | patch -p0 -d /
--- /etc/redis/redis.conf.orig  2018-06-18 19:12:58.000000000 +0200
+++ /etc/redis/redis.conf       2019-02-17 08:33:14.551998177 +0100
@@ -478,6 +478,7 @@
 # use a very strong password otherwise it will be very easy to break.
 #
 # requirepass foobared
+requirepass YOUR_SHA256_REDIS_PASSWORD_HERE
 
 # Command renaming.
 #
EOF
service redis-server restart

cat << 'EOF' | patch -p0 -d /
--- /var/www/nextcloud/config/config.php.bak1   2019-01-16 10:37:32.305366629 +0100
+++ /var/www/nextcloud/config/config.php        2019-02-17 08:40:06.881989885 +0100
@@ -21,7 +21,15 @@
   'logtimezone' => 'UTC',
   'installed' => true,
   'htaccess.RewriteBase' => '/',
+  'memcache.locking' => '\OC\Memcache\Redis',
+  'memcache.distributed' => '\OC\Memcache\Redis',
+  'redis' => [
+       'host'     => '127.0.0.1',
+       'port'     => 6379,
+       'password' => 'YOUR_SHA256_REDIS_PASSWORD_HERE',
+       'timeout'  => 1.5,
+  ],
   'mail_smtpmode' => 'sendmail',
   'mail_from_address' => 'operator-cloud-tree',
   'mail_domain' => 'mail.inf.fh-bonn-rhein-sieg.de',
EOF

####################

exit # then end
