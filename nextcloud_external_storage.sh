#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enable External Storage
#
# Ref.:
#  https://docs.nextcloud.com/server/stable/admin_manual/configuration_files/external_storage_configuration_gui.html
#  https://docs.nextcloud.com/server/stable/admin_manual/configuration_files/external_storage/smb.html

apt install php-smbclient smbclient # for External Storage via SMB/CIFS
phpenmod smbclient
systemctl restart php7.0-fpm

# Enable "External storage support" App in ownCloud/Nextcloud
# Enable User External Storage
