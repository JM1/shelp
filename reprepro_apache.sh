#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Share reprepro debian package repository using Apache2
#

#TODO: Update this file to newest apache2 version!
cat << 'EOF' > /etc/apache2.default/conf-available/jm-repo
#
# Debian Apt Repository
# 2013 Jakob Meng, <jakobmeng@web.de>
#
# Ref.:
#  http://wiki.debian.org/SettingUpSignedAptRepositoryWithReprepro#Configuring_Apache
#  http://www.jejik.com/articles/2006/09/setting_up_and_managing_an_apt_repository_with_reprepro/

Alias /jm-repo/ "/var/jm-repo/"

# Allow directory listings so that people can browse the repository from their browser too
<Directory "/var/jm-repo/">
	Options Indexes FollowSymLinks MultiViews

	#DirectoryIndex ist eigentlich nicht erforderlich, weil es sowieso Standard ist!
	DirectoryIndex index.html
	AllowOverride Options
	Order allow,deny
	allow from all
</Directory>

# Hide the conf/ directory for all repositories
<Directory "/var/jm-repo/*/conf/">
	Order allow,deny
	Deny from all
</Directory>

# Hide the db/ directory for all repositories
<Directory "/var/jm-repo/*/db/">
	Order allow,deny
	Deny from all
</Directory>

# Hide the incoming/ directory for all repositories
<Directory "/var/jm-repo/*/incoming/">
        Order allow,deny
        Deny from all
</Directory>
EOF

exit # the end
