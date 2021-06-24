#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Install ownCloud or Nextcloud in VM with Debian 8 (Jessie)
#

# Follow libvirt.sh to create a virtual machine with Debian 8 (Jessie)
# Follow debian_setup.sh to install Debian 8 (Jessie)
# Follow exim.sh to configure Exim for mail support
# Follow apt_unattended_upgrades.sh to enable unattended upgrades for APT
# Follow chrony.sh to configure time synchronization with chrony
# Follow apache_setup.sh to install Apache2
# Follow apache_localhost.sh to bind Apache2 to localhost
# Follow apache_php-fpm.sh to set up php-fpm and libapache2-mod-fcgid for Apache2
# Follow apache_ssl.sh to set up HTTPs/SSL encryption for Apache2
# Follow apache_http2.sh to enable HTTP/2 module on Apache2

# NOTE: Do not enable mod-evasive like described in apache_mod-evasive.sh,
#       because it is known to cause problems, see https://forum.owncloud.org/viewtopic.php?f=17&t=7240

ssh -L localhost:8080:localhost:80 _USER_@_HOSTNAME_

# Import FB02 root certificate
# Ref.: http://ux-2s18.inf.fh-bonn-rhein-sieg.de/faq/allgemeine-informationen/stammzertifikat-root-certificate-des-fb-informatik
wget --directory-prefix=/etc/ssl/certs/ http://ux-2s18.inf.fh-bonn-rhein-sieg.de/faq/images/FBInf_FHBRS_RootCert2008.pem
# NOTE: See also 'Install local or self-signed CA certificates' in openssl.sh!




# (Optional) If you place your ownCloud data directory outside of /var/www/owncloud/ then create it before configuration with:
mkdir /var/oc_data
chown -R www-data.www-data /var/oc_data/

####################
# Setup ownCloud (using MySQL)

wget -nv https://download.owncloud.org/download/repositories/stable/Debian_8.0/Release.key -O /etc/apt/trusted.gpg.d/download.owncloud.org.gpg
#wget -nv https://download.owncloud.org/download/repositories/production/Debian_9.0/Release.key -O /etc/apt/trusted.gpg.d/download.owncloud.org.gpg

cat << 'EOF' >> "/etc/apt/sources.list.d/apps-owncloud.list"
deb http://download.owncloud.org/download/repositories/stable/Debian_8.0/ /
EOF

apt-get update
apt-get install owncloud

# Follow guides at
#  https://doc.owncloud.org/server/9.0/admin_manual/installation/installation_wizard.html
#  https://doc.owncloud.org/server/9.0/admin_manual/configuration_server/harden_server.html

# Email Server:
#     Send Mode: sendmail
#  From address: operator+ux-2g01@mail.inf.fh-bonn-rhein-sieg.de

# User Mgmt:
# Only local user mgmt is used!

cp -raiv /etc/apache2/conf-available/owncloud.conf /etc/apache2/conf-available/owncloud.conf.orig
cp -raiv /var/www/owncloud/config/config.php /var/www/owncloud/config/config.php.orig

# NOTE: Do not create copies of /var/www/owncloud/.htaccess in /var/www/owncloud/, because else ownCloud's integrity check will fail!
# cp -raiv /var/www/owncloud/.htaccess /var/www/owncloud/.htaccess.orig

vi /var/www/owncloud/config/config.php 
# Adapt 'trusted_domains' and 'overwrite.cli.url' to your needs, e.g. to
# ...
#   'trusted_domains' => 
#   array (
#     0 => 'localhost:8443',
#     1 => 'cloud.tree.h-brs.de',
#   ),
# ...
#   'overwrite.cli.url' => 'https://cloud.tree.h-brs.de/owncloud',
# ...
#

# Do not listen to localhost only any longer
cp -raiv /etc/apache2/ports.conf.orig /etc/apache2/ports.conf

service apache2 restart

####################
# Setup Nextcloud (using MySQL or MariaDB)

# Fetch prerequisites
# Ref.: https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html#prerequisites-for-manual-installation
# On Debian 10 (Buster)
# PHP modules openssl and session and zlib
apt install php php-ctype php-curl php-dom php-gd php-iconv php-json php-xml php-mbstring php-posix php-simplexml php-xmlreader php-xmlwriter php-zip
apt install php-fileinfo php-bz2 php-intl # recommended packages
apt install php-exif php-gmp php-imagick # optional, for specific apps and preview generation
apt install php-ldap php-smbclient php-ftp php-imap # optional, for integrations and external user authentication
apt install php-bcmath php-gmp # optional, for passwordless login
apt install php-mysql # optional, if you use MySQL or MariaDB as your database

# Follow guide at https://docs.nextcloud.com/server/18/admin_manual/configuration_server/index.html

####################




# Option 1: Defining background jobs via crontab
cat << 'EOF' >> /etc/cron.d/owncloud
# /etc/cron.d/owncloud: crontab fragment for ownCloud 10
# Ref.: https://doc.owncloud.org/server/10.0/admin_manual/configuration_server/background_jobs_configuration.html
# m h dom mon dow user  command
*/15  *  *  *  * www-data /usr/bin/php -f /var/www/owncloud/cron.php

EOF
service cron reload
# Open ownCloud Settings in your Browser ( https://cloud.tree.h-brs.de/settings/admin )
# => "Admin" => "General" => "Cron" => 
# => Choose "Cron: Use system's cron service to call the cron.php file every 15 minutes."

# Option 2: Defining background jobs via systemd
# Ref.: https://docs.nextcloud.com/server/14/admin_manual/configuration_server/background_jobs_configuration.html
cat << 'EOF' > /etc/systemd/system/nextcloudcron.service
[Unit]
Description=Nextcloud cron.php job

[Service]
User=www-data
ExecStart=/usr/bin/php -f /var/www/nextcloud/cron.php

[Install]
WantedBy=basic.target
EOF

cat << 'EOF' > /etc/systemd/system/nextcloudcron.timer
[Unit]
Description=Run Nextcloud cron.php every 15 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
Unit=nextcloudcron.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl start nextcloudcron.timer
systemctl enable nextcloudcron.timer

# Select the option Cron in the Nextcloud admin menu for background jobs



# Increase the maximum upload size
# Ref.: https://docs.nextcloud.com/server/18/admin_manual/installation/source_installation.html#php-ini-configuration-notes
cat << 'EOF' >> /var/www/nextcloud/.user.ini

upload_max_filesize=2048M
post_max_size=2048M
memory_limit=512M
EOF
# NOTE: Changes to /var/www/nextcloud/.user.ini will be lost when upgrading
#       Nextcloud, hence you have to reapply changes to this file!

# On Debian 9 (Stretch)
systemctl restart php7.0-fpm.service

# On Debian 10 (Buster)
systemctl restart php7.3-fpm.service

# Check https://cloud.tree.h-brs.de/settings/admin/overview


########################################
#
# Optimize database configuration and enable MySQL 4-byte support
#
# Ref.:
# [1] https://docs.nextcloud.com/server/stable/admin_manual/configuration_database/linux_database_configuration.html
# [2] https://docs.nextcloud.com/server/stable/admin_manual/configuration_database/mysql_4byte_support.html

# On Debian 9 (Stretch)
cat << 'EOF' >> /etc/mysql/conf.d/99-nextcloud.cnf
# 2020 Jakob Meng, <jakobmeng@web.de>
# Nextcloud Database configuration
[mysqld]
transaction_isolation = READ-COMMITTED
binlog_format = ROW

innodb_buffer_pool_size=4G
innodb_file_per_table=1

# MariaDB 10.2 or earlier
innodb_large_prefix=true
innodb_file_format=barracuda
EOF

# On Debian 10 (Buster)
cat << 'EOF' >> /etc/mysql/conf.d/99-nextcloud.cnf
# 2020 Jakob Meng, <jakobmeng@web.de>
# Nextcloud Database configuration
[mysqld]
transaction_isolation = READ-COMMITTED
binlog_format = ROW

innodb_buffer_pool_size=4G
innodb_file_per_table=1
EOF

systemctl restart mariadb.service

# Verify settings
mysqladmin -p variables

# Migrate databases from innodb_file_format 'Antelope' to 'Barracuda'
mysql -uroot -p
MariaDB> show variables like 'innodb_file_format';
# If your innodb_file_format is set as ‘Antelope’ you must upgrade your file format using:
MariaDB> SELECT NAME, SPACE, FILE_FORMAT FROM INFORMATION_SCHEMA.INNODB_SYS_TABLES WHERE NAME like "ocdb%";
MariaDB> USE INFORMATION_SCHEMA;
MariaDB> SELECT CONCAT("ALTER TABLE `", TABLE_SCHEMA,"`.`", TABLE_NAME, "` ROW_FORMAT=DYNAMIC;") AS MySQLCMD FROM TABLES WHERE TABLE_SCHEMA = "ocdb";
# "This will return an SQL command for each table in the nextcloud database. 
#  The rows can be quickly copied into a text editor, the “|”s replaced and the
#  SQL commands copied back to the MariaDB shell. If no error appeared (in 
#  doubt check step 2) all is done and nothing is left to do here. It can be
#  proceded with the MySQL instructions from step 3 onwards." [2]

# "It is possible, however, that some tables cannot be altered. The operations 
#  fails with: “ERROR 1478 (HY000): Table storage engine ‘InnoDB’ does not 
#  support the create option ‘ROW_FORMAT’”. In that case the failing tables
#  have a SPACE value of 0 in step 2. It basically means that the table does
#  not have an index file of its own, which is required for the Barracuda 
#  format. This can be solved with a slightly different SQL command:" [2]
MariaDB> ALTER TABLE `ocdb`.`oc_tablename` ROW_FORMAT=DYNAMIC, ALGORITHM=COPY;

MariaDB> ALTER DATABASE ocdb CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

cd /var/www/nextcloud/
sudo -u www-data php occ config:system:set mysql.utf8mb4 --type boolean --value="true"
sudo -u www-data php occ maintenance:repair

########################################

exit # the end
