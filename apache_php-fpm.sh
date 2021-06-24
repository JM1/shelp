#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Set up php-fpm and libapache2-mod-fcgid for Apache2
#
# Ref.:
# [1] https://localhorst.org/http-2-0-debian-9-apache-2-4-umstellung-auf-php-fpm/
# [2] https://docs.nextcloud.com/server/stable/admin_manual/installation/server_tuning.html
# [3] https://stackoverflow.com/a/25098060

apt install php-fpm libapache2-mod-fcgid

# On Debian 9 (Stretch)
a2dismod php7.0 mpm_prefork
a2enmod mpm_event
a2enmod proxy_fcgi setenvif
a2enconf php7.0-fpm

# On Debian 10 (Buster)
a2dismod mpm_prefork
a2enmod mpm_event
a2enmod proxy_fcgi setenvif
a2enconf php7.3-fpm

# "If you are using a default installation of php-fpm you might have noticed
#  excessive load times on the web interface or even sync issues. This is due
#  to the fact that each simultaneous request of an element is handled by a
#  separate PHP-FPM process. So even on a small installation you should allow
#  more processes to run. For example on a machine with 4GB of RAM and 1GB of
#  MySQL cache following values in your www.conf file should work:
#    pm = dynamic
#    pm.max_children = 120
#    pm.start_servers = 12
#    pm.min_spare_servers = 6
#    pm.max_spare_servers = 18
#  Depending on your current PHP version you should find this file e.g.
#  under /etc/php/7.2/fpm/pool.d/www.conf" [2]

# "A better way to determine max_children is to find out how much each child
#  process uses, then factor in the maximum RAM you would like php-fpm to use
#  and then divide the values. E.g. If I have a 16GB server, I can run the
#  following command to determine how much ram each php-fpm child consumes:
#    ps -ylC php-fpm --sort:rss
#
#  NOTE: It may be required to explicitly specify user if php-fpm is running
#        under the different one:
#          ps -ylC php-fpm --sort:rss -u www-data
#        where www-data is the user under which php-fpm is being run.
#
#  You are on the lookout for the RSS column; it states resident memory and
#  is measured in KB. If I have an average of 50MB per process and I want to
#  use a maximum of 10GB for php-fpm processes, then all I do is 
#  10000MB \ 50MB = 200. So, on that basis, I can use 200 children for my
#  stated memory consumption.
#
#  Now, with regards to the servers, you will want to set the max_spare_servers
#  to x2 or x4 the number of cores. So if you have an 8 core CPU then you can
#  start off with a value of 16 for max_spare_servers and go up to 32.
#
#  Also, in addition to dynamic, the pm value can also be set to static or
#  on-demand. Static will always have a fixed number of servers running at any
#  given time. This is good if you have a consistent amount of users or you
#  want to guarantee you don't breach the max memory. On-demand will only start
#  processes when there is a need for them. The downside is obviously having
#  to constantly start/kill processes which will usually translate into a very
#  slight delay in request handling. The upside, you only use resources when
#  you need them. "Dynamic" always starts X amount of servers specified in the
#  start_servers option and creates additional processes on an as-need basis.
#
#  If you are still experiencing issues with memory then consider changing pm
#  to on-demand.
#
#  This is a general guideline, your settings may need further tweaking. It is
#  really a case of playing with the settings and running benchmarks for maximum
#  performance and optimal resource usage. It is somewhat tedious but it is the
#  best way to determine these types of settings because each setup is
#  different." [3]

# For 8 core CPU with 12 GB RAM
# On Debian 9 (Stretch)
cat << 'EOF'  | patch -p0 -d /
--- /etc/php/7.0/fpm/pool.d/www.conf.orig       2019-03-08 11:01:24.000000000 +0100
+++ /etc/php/7.0/fpm/pool.d/www.conf    2020-01-14 10:29:42.641953007 +0100
@@ -110,22 +110,22 @@
 ; forget to tweak pm.* to fit your needs.
 ; Note: Used when pm is set to 'static', 'dynamic' or 'ondemand'
 ; Note: This value is mandatory.
-pm.max_children = 5
+pm.max_children = 120
 
 ; The number of child processes created on startup.
 ; Note: Used only when pm is set to 'dynamic'
 ; Default Value: min_spare_servers + (max_spare_servers - min_spare_servers) / 2
-pm.start_servers = 2
+pm.start_servers = 24
 
 ; The desired minimum number of idle server processes.
 ; Note: Used only when pm is set to 'dynamic'
 ; Note: Mandatory when pm is set to 'dynamic'
-pm.min_spare_servers = 1
+pm.min_spare_servers = 16
 
 ; The desired maximum number of idle server processes.
 ; Note: Used only when pm is set to 'dynamic'
 ; Note: Mandatory when pm is set to 'dynamic'
-pm.max_spare_servers = 3
+pm.max_spare_servers = 32
 
 ; The number of seconds after which an idle process will be killed.
 ; Note: Used only when pm is set to 'ondemand'
EOF
systemctl restart php7.0-fpm.service
systemctl restart apache2

# On Debian 10 (Buster)
cat << 'EOF'  | patch -p0 -d /
--- /etc/php/7.3/fpm/pool.d/www.conf.orig       2020-07-05 08:46:45.000000000 +0200
+++ /etc/php/7.3/fpm/pool.d/www.conf    2020-08-23 16:31:07.018813812 +0200
@@ -110,22 +110,22 @@
 ; forget to tweak pm.* to fit your needs.
 ; Note: Used when pm is set to 'static', 'dynamic' or 'ondemand'
 ; Note: This value is mandatory.
-pm.max_children = 5
+pm.max_children = 120
 
 ; The number of child processes created on startup.
 ; Note: Used only when pm is set to 'dynamic'
 ; Default Value: min_spare_servers + (max_spare_servers - min_spare_servers) / 2
-pm.start_servers = 2
+pm.start_servers = 24
 
 ; The desired minimum number of idle server processes.
 ; Note: Used only when pm is set to 'dynamic'
 ; Note: Mandatory when pm is set to 'dynamic'
-pm.min_spare_servers = 1
+pm.min_spare_servers = 16
 
 ; The desired maximum number of idle server processes.
 ; Note: Used only when pm is set to 'dynamic'
 ; Note: Mandatory when pm is set to 'dynamic'
-pm.max_spare_servers = 3
+pm.max_spare_servers = 32
 
 ; The number of seconds after which an idle process will be killed.
 ; Note: Used only when pm is set to 'ondemand'
EOF
systemctl restart php7.3-fpm.service
systemctl restart apache2

exit # the end
