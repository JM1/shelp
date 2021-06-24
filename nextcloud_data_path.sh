#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Change data folder of Nextcloud or ownCloud
#

service apache2 stop

mv -i /var/www/owncloud/data/ /var/oc_data
vi /var/www/owncloud/config/config.php
# Edit or add line  
#  'datadirectory' => '/var/oc_data',

service apache2 start
