#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Upgrade Nextcloud using the command line based updater
#
# Ref.:
#  https://docs.nextcloud.com/server/latest/admin_manual/maintenance/update.html
#  https://docs.nextcloud.com/server/latest/admin_manual/maintenance/manual_upgrade.html

# NOTE: If Nextcloud upgrade fails at "Verifying integrity" step with error "Parsing response failed." then
#       it might be required to temporarily increase the maximum amount of memory a PHP script may consume.
systemctl stop php7.3-fpm.service
cd /var/www/nextcloud/updater/
sudo -u www-data php occ maintenance:repair # removes failed upgrade
cp -raiv /etc/php/7.3/fpm/php.ini /etc/php/7.3/fpm/php.ini.orig
sed -i -e 's/^memory_limit = .*/memory_limit = 2048M/g' /etc/php/7.3/fpm/php.ini
systemctl start php7.3-fpm.service

cd /var/www/nextcloud/updater/
sudo -u www-data php updater.phar
#
# or
#
# Visit https://cloud.tree.h-brs.de/settings/admin/overview and 
# and click button "Open Updater"
# and click button "Start update"
# and when asked for "Keep maintenance mode active?",
# then choose "Yes (for usage with command line tool)"
cd /var/www/nextcloud/
sudo -u www-data php occ maintenance:mode --on
sudo -u www-data php occ upgrade
sudo -u www-data php occ db:add-missing-indices # optional
sudo -u www-data php occ db:add-missing-columns # optional
sudo -u www-data php occ db:convert-filecache-bigint # optional
sudo -u www-data php occ maintenance:mode --off

# Undo PHP config changes
mv -iv /etc/php/7.3/fpm/php.ini.orig /etc/php/7.3/fpm/php.ini
systemctl restart php7.3-fpm.service

# NOTE: Visit https://cloud.tree.h-brs.de/settings/admin/overview and watch for Security & setup warnings!

# NOTE: Changes to e.g. /var/www/nextcloud/.user.ini will be lost after upgrading
#       Nextcloud, hence you have to readd files or reapply changes!
