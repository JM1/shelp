#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Install Gitea binary on Debian 10 (Buster)
#
# Ref.:
#  https://docs.gitea.io/en-us/install-from-binary/
#  https://docs.gitea.io/en-us/linux-service/

# Suppose smtp.infcs.de is your smtp server and infcs.de is your domain name.

# download Gitea binary
GITEA_VERSION=1.14.1
cd /usr/local/bin/
wget https://dl.gitea.io/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64
chmod +x gitea-${GITEA_VERSION}-linux-amd64
ln -s gitea-${GITEA_VERSION}-linux-amd64 gitea

# verify Gitea binary
gpg --keyserver keys.openpgp.org --recv 7C9E68152594688862D62AF62D9AE806EC1592E2
wget https://dl.gitea.io/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64.asc
gpg --verify gitea-${GITEA_VERSION}-linux-amd64.asc gitea-${GITEA_VERSION}-linux-amd64
rm gitea-${GITEA_VERSION}-linux-amd64.asc

# get necessary packages
apt install git git-lfs

# add user git to enable ssh connections to Gitea
adduser \
   --system \
   --group \
   --shell /bin/bash \
   --gecos 'Git Version Control' \
   --disabled-password \
   git

# prepare environment
mkdir -p /var/lib/gitea/{custom,data} /var/log/gitea/
chown -R git:git /var/lib/gitea/ /var/log/gitea/
chmod -R 750 /var/lib/gitea/ /var/log/gitea/
mkdir /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea

# create initial config file
cat << EOF >> /etc/gitea/app.ini
; 2021 Jakob Meng, <jakobmeng@web.de>
; Ref.:
; https://github.com/go-gitea/gitea/blob/master/custom/conf/app.example.ini
; https://github.com/go-gitea/gitea/blob/master/docker/root/etc/templates/app.ini
; https://github.com/go-gitea/gitea/blob/master/docker/root/etc/s6/gitea/setup

[server]
DOMAIN = $(hostname --fqdn)
HTTP_PORT = 80
; ROOT_URL = http://$(hostname --fqdn)/
DISABLE_SSH = false

[service]
REQUIRE_SIGNIN_VIEW    = true
ENABLE_NOTIFY_MAIL     = true
REGISTER_EMAIL_CONFIRM = true

[database]
DB_TYPE = sqlite3

[mailer]
ENABLED        = true
FROM           = sysmsg+openstack.$(hostname)@infcs.de
MAILER_TYPE    = smtp
HOST           = smtp.infcs.de:25
IS_TLS_ENABLED = false
; USER         = username
; PASSWD       = password

[log]
MODE      = console,file
ROOT_PATH = /var/log/gitea/

EOF
chown root:git /etc/gitea/app.ini
chmod 660 /etc/gitea/app.ini

# run Gitea as Linux service using systemd
cat << 'EOF' >> /etc/systemd/system/gitea.service
# 2021 Jakob Meng, <jakobmeng@web.de>
# Ref.:
#  https://docs.gitea.io/en-us/linux-service/
#  https://github.com/go-gitea/gitea/blob/master/contrib/systemd/gitea.service
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]

# Modify these two values and uncomment them if you have
# repos with lots of files and get an HTTP error 500 because
# of that
#LimitMEMLOCK=infinity
#LimitNOFILE=65535

RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea

# If you want to bind Gitea to a port below 1024, uncomment
# the two values below, or use socket activation to pass Gitea its ports as above
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

# open http://$(hostname --fqdn)/ in browser and finish installation
# NOTE: Some settings like REQUIRE_SIGNIN_VIEW are not prepopulated from preexisting /etc/gitea/app.ini!
# after installation has finished continue here

# check settings
vi /etc/gitea/app.ini
sed -i -e '/^\[service\]$/,/^\[/ s/REQUIRE_SIGNIN_VIEW[ ]*=[ ]*false/REQUIRE_SIGNIN_VIEW = true/g' /etc/gitea/app.ini
sed -i -e '/^\[service\]$/,/^\[/ s/ENABLE_NOTIFY_MAIL[ ]*=[ ]*false/ENABLE_NOTIFY_MAIL = true/g' /etc/gitea/app.ini
sed -i -e '/^\[service\]$/,/^\[/ s/REGISTER_EMAIL_CONFIRM[ ]*=[ ]*false/REGISTER_EMAIL_CONFIRM = true/g' /etc/gitea/app.ini
sed -i -e '/^\[mailer\]$/,/^\[/ s/ENABLED[ ]*=[ ]*false/ENABLED = true/g' /etc/gitea/app.ini
sed -i -e '/^\[mailer\]$/,/^\[/ s/IS_TLS_ENABLED[ ]*=[ ]*true/IS_TLS_ENABLED = false/g' /etc/gitea/app.ini
sed -i -e '/^\[log\]$/,/^\[/ s/MODE[ ]*=.*$/MODE = console,file/g' /etc/gitea/app.ini

# restart Gitea to apply changes
systemctl restart gitea

# Revert temporary write rights for user git that were granted for Gitea's web installer
chmod 750 /etc/gitea
chmod 640 /etc/gitea/app.ini

exit # the end
