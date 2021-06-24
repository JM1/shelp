#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Install Gitea with Docker on Debian 10 (Buster)
#
# Ref.:
#  https://docs.gitea.io/en-us/install-with-docker/
#  https://docs.gitea.io/en-us/install-from-binary/

# Suppose smtp.infcs.de is your smtp server and infcs.de is your domain name.

# A Message Transfer Agent (MTA) like Exim4 must be running on the host system if email notifications should work,
# because Watchtower can only send mails using a local MTA.
# Ref.: https://github.com/containrrr/watchtower/issues/572
#
# To setup an MTA e.g. follow exim.sh

# Change Exim4 configuration to allow relaying mails from Docker containers
LANG=C dpkg-reconfigure -plow exim4-config
# As Exim4's mail server configuration type choose 'mail sent by smarthost; received via SMTP or fetchmail'. Add host ip
# address (here: 172.31.0.1) on Docker network 'gitea' to list of 'IP-addresses to listen on for incoming SMTP
# connections'. Leave 'Other destinations for which mail is accepted' empty/blank. Add subnet '172.31.0.0/16' from 
# Docker network 'gitea' to list of 'Machines to relay mail for'.
#
# or non-interactively
# Ref.: /var/lib/dpkg/info/exim4-config.config
#
# debconf questions
sed -i \
    -e "s/^dc_eximconfig_configtype=.*/dc_eximconfig_configtype='smarthost'/g" \
    -e "s/^dc_local_interfaces=.*/dc_local_interfaces='127.0.0.1 ; ::1 ; 172.31.0.1'/g" \
    -e "s/^dc_minimaldns=.*/dc_minimaldns='false'/g" \
    -e "s/^dc_other_hostnames=.*/dc_other_hostnames=''/g" \
    -e "s/^dc_readhost=.*/dc_readhost='$(hostname).infcs.de'/g" \
    -e "s/^dc_smarthost=.*/dc_smarthost='smtp.infcs.de'/g" \
    -e "s/^dc_use_split_config=.*/dc_use_split_config='false'/g" \
    -e "s/^dc_relay_domains=.*/dc_relay_domains=''/g" \
    -e "s/^dc_relay_nets=.*/dc_relay_nets='172.31.0.0/24'/g" \
    -e "s/^dc_hide_mailname=.*/dc_hide_mailname='true'/g" \
    -e "s/^dc_mailname_in_oh=.*/dc_mailname_in_oh='true'/g" \
    -e "s/^dc_localdelivery=.*/dc_localdelivery='mail_spool'/g" \
    /etc/exim4/update-exim4.conf.conf
#
# debconf question exim4/dc_postmaster
sed -i -e "s/^root: .*/root: sysmsg+openstack.$(hostname)@infcs.de/g" /etc/aliases 
#
# debconf question exim4/mailname
echo "$(hostname).infcs.de" > /etc/mailname
#
# Synchronize debconf database with exim4-config's config which will help during
# package updates because debconf will not complain about config changes

cat << EOF | debconf-set-selections
exim4-config   exim4/dc_eximconfig_configtype   select  mail sent by smarthost; received via SMTP or fetchmail
exim4-config   exim4/dc_localdelivery           select  mbox format in /var/mail/
exim4-config   exim4/dc_local_interfaces        string  127.0.0.1 ; ::1 ; 172.31.0.1
exim4-config   exim4/dc_minimaldns              boolean false
exim4-config   exim4/dc_other_hostnames         string  
exim4-config   exim4/dc_postmaster              string  sysmsg+openstack.$(hostname)@infcs.de
exim4-config   exim4/dc_readhost                string  $(hostname).infcs.de
exim4-config   exim4/dc_relay_nets              string  172.31.0.0/24
exim4-config   exim4/dc_smarthost               string  smtp.infcs.de
exim4-config   exim4/hide_mailname              boolean true
exim4-config   exim4/mailname                   string  $(hostname).infcs.de
EOF
dpkg-reconfigure -f noninteractive exim4-config

systemctl restart exim4.service

apt install docker.io docker-compose git git-lfs

adduser \
   --system \
   --group \
   --shell /bin/bash \
   --gecos 'Git Version Control' \
   --disabled-password \
   git

sudo -u git ssh-keygen -t rsa -b 4096 -C "Gitea Host Key"

cat << EOF >> /home/git/.ssh/authorized_keys
# SSH public key from git user
$(cat /home/git/.ssh/id_rsa.pub)

# Git public keys from Gitea users, filled from Gitea Docker container
EOF
chown git.git /home/git/.ssh/authorized_keys
chmod g-rwx,o-rwx /home/git/.ssh/authorized_keys

mkdir -p /var/lib/gitea/
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/

cat << 'EOF' >> /usr/local/bin/gitea-ssh-forwarder
#!/bin/sh
# 2021 Jakob Meng, <jakobmeng@web.de>
ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
EOF
chmod a+x /usr/local/bin/gitea-ssh-forwarder

mkdir -p /app/gitea/
ln -s /usr/local/bin/gitea-ssh-forwarder /app/gitea/gitea

mkdir /etc/gitea
cd /etc/gitea
chmod u=rwx,g=rx,o= /etc/gitea

# Ask Steffen Kaiser for an email address to use for sending mails with Gitea and Watchtower
# Ref.: https://faq.inf.h-brs.de/faq/informationen-fuer-labore/systemmeldungen-von-laborservern-phys-virtuell

cat << EOF >> /etc/gitea/docker-compose.yml
# 2021 Jakob Meng, <jakobmeng@web.de>
# Gitea with Docker

version: "3"

networks:
  gitea:
    external: false
    ipam:
      driver: default
      config:
        - subnet: "172.31.0.0/24"

services:
  gitea:
    container_name: gitea
    environment:
      USER_UID: '$(id -u git)'
      USER_GID: '$(id -g git)'
      GITEA__server__ROOT_URL: 'http://$(hostname --fqdn)/'
      GITEA__service__REQUIRE_SIGNIN_VIEW: 'true'
      GITEA__service__ENABLE_NOTIFY_MAIL: 'true'
      GITEA__service__REGISTER_EMAIL_CONFIRM: 'true'
      GITEA__mailer__ENABLED: 'true'
      GITEA__mailer__FROM: 'sysmsg+openstack.$(hostname)@infcs.de'
      GITEA__mailer__MAILER_TYPE: 'smtp'
      GITEA__mailer__HOST: '172.31.0.1:25'
      GITEA__mailer__IS_TLS_ENABLED: 'false'
      #GITEA__mailer__USER: 'username'
      #GITEA__mailer__PASSWD: 'password'
    image: gitea/gitea:latest
    labels:
      - "com.centurylinklabs.watchtower.scope=gitea"
    networks:
      - gitea
    ports:
      - "80:3000"
      - "127.0.0.1:2222:22"
    restart: always
    volumes:
      - /home/git/.ssh/:/data/git/.ssh
      - /var/lib/gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro

  watchtower:
    container_name: gitea_watchtower
    environment:
      TZ: 'Europe/Berlin'
      WATCHTOWER_CLEANUP: 'true'
      WATCHTOWER_INCLUDE_RESTARTING: 'true'
      WATCHTOWER_ROLLING_RESTART: 'true'
      WATCHTOWER_TIMEOUT: '30s'
      WATCHTOWER_SCOPE: 'gitea'
      WATCHTOWER_NOTIFICATIONS: 'email'
      WATCHTOWER_NOTIFICATION_EMAIL_FROM: 'sysmsg+openstack.$(hostname)@infcs.de'
      WATCHTOWER_NOTIFICATION_EMAIL_TO: 'sysmsg+openstack.$(hostname)@infcs.de'
      WATCHTOWER_NOTIFICATION_EMAIL_SERVER: '172.31.0.1'
      WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT: '25'
      WATCHTOWER_NOTIFICATION_EMAIL_SERVER_TLS_SKIP_VERIFY: 'true'
      WATCHTOWER_NOTIFICATION_EMAIL_SUBJECTTAG: '[WATCHTOWER GITEA]'
      WATCHTOWER_NOTIFICATION_EMAIL_DELAY: '3'
    image: containrrr/watchtower:latest
    labels:
      - "com.centurylinklabs.watchtower.scope=gitea"
    networks:
      - gitea
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

EOF
chmod u=rw,g=r,o= /etc/gitea/docker-compose.yml

# run containers in background
docker-compose up -d

# verify that all containers are up and running
docker ps

# view output of Gitea container
docker logs gitea

# view output of Watchtower container
docker logs gitea_watchtower

exit # the end
