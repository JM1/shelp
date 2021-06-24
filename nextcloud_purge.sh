#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Removing/Purging ownCloud / Nextcloud, e.g. for a clean reinstall
#
# NOTE: You'll loose your ownCloud/Nextcloud data completely!

a2dissite owncloud.conf
systemctl stop apache2

rm /etc/apt/apt.conf.d/55owncloud_upgrade
rm /usr/local/bin/owncloud_upgrade
rm /etc/cron.daily/owncloud_backup
rm /etc/default/owncloud_backup
apt-get purge owncloud owncloud-deps-php5 owncloud-files

mysql -uroot -p -e "drop database \`ocdb\`;"
rm -r /var/www/owncloud/
rm -r /var/oc_data/

rm /var/cache/owncloud/version.php.last
rmdir /var/cache/owncloud/
rm /etc/apache2/sites-available/owncloud.conf
rm /etc/apache2/conf-available/owncloud.conf
rm /etc/cron.d/owncloud
rm /etc/apt/sources.list.d/apps-owncloud.list

rm /etc/systemd/system/nextcloudcron.service
rm /etc/systemd/system/nextcloudcron.timer
