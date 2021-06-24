#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Exim Internet Mailer Setup
#
# Ref.:
#  https://faq.inf.h-brs.de/faq/informationen-fuer-labore/exim
#  https://faq.inf.h-brs.de/faq/informationen-fuer-labore/systemmeldungen-von-laborservern-phys-virtuell
#  https://manpages.debian.org/buster/exim4-config/update-exim4.conf.8.en.html

# Suppose
#  smtp.inf.h-brs.de or smtp.infcs.de is a stmp server
#  _HOSTNAME_ is your hostname
#  _DOMAIN_ is your domain name

# NOTE: _HOSTNAME_ probably needs a valid dns entry or else your smtp server might throw errors.

apt-get install exim4

if [ -z "$(grep $(hostname --fqdn) /etc/mailname)" ]; then
    echo "$(hostname --fqdn)" > /etc/mailname
fi

# Show current configuration
debconf-show exim4-config
debconf-get-selections | grep exim4-config | sort

LANG=C dpkg-reconfigure -plow exim4-config
# Exim4's mail server configuration type: 'mail sent by smarthost; no local mail'
# System mail name: '_HOSTNAME_._DOMAIN_'
# IP-addresses to listen on for incoming SMTP connections: '127.0.0.1 ; ::1'
# Other destinations for which mail is accepted: '' (Empty String)
# Visible domain name for local users: '_HOSTNAME_._DOMAIN_' or '' (Empty String)
# IP address or host name of the outgoing smarthost: 'smtp.inf.h-brs.de' or 'smtp.infcs.de'
# Keep number of DNS-queries minimal (Dial-on-Demand)? '<No>'
# Split configuration into small files? '<No>'
# Root and postmaster mail recipient: '_EMAIL_RECIPIENT_', e.g. 'sysmsg+openstack.$(hostname)@infcs.de'
#
# NOTE: Option exim4/dc_postmaster ('Root and postmaster mail recipient') will set 'root:' in
#       /etc/aliases and will only be asked if it has not been set in /etc/aliases already!
#       Ref.:
#        /var/lib/dpkg/info/exim4-config.config
#        /var/lib/dpkg/info/exim4-config.postinst
#
# or non-interactively
# Ref.: /var/lib/dpkg/info/exim4-config.config
#
# debconf questions
#  exim4/dc_eximconfig_configtype   select  mail sent by smarthost; no local mail
#  exim4/dc_local_interfaces        string  127.0.0.1 ; ::1
#  exim4/dc_minimaldns              boolean false
#  exim4/dc_other_hostnames         string  
#  exim4/dc_postmaster              string  sysmsg+openstack.$(hostname)@infcs.de
#  exim4/dc_readhost                string  $(hostname --fqdn)
#  exim4/dc_smarthost               string  smtp.infcs.de
#  exim4/mailname                   string  $(hostname --fqdn)
#  exim4/use_split_config           boolean false
sed -i \
    -e "s/^dc_eximconfig_configtype=.*/dc_eximconfig_configtype='satellite'/g" \
    -e "s/^dc_local_interfaces=.*/dc_local_interfaces='127.0.0.1 ; ::1'/g" \
    -e "s/^dc_minimaldns=.*/dc_minimaldns='false'/g" \
    -e "s/^dc_other_hostnames=.*/dc_other_hostnames=''/g" \
    -e "s/^dc_readhost=.*/dc_readhost='$(hostname --fqdn)'/g" \
    -e "s/^dc_smarthost=.*/dc_smarthost='smtp.inf.h-brs.de'/g" \
    -e "s/^dc_use_split_config=.*/dc_use_split_config='false'/g" \
    -e "s/^dc_relay_domains=.*/dc_relay_domains=''/g" \
    -e "s/^dc_relay_nets=.*/dc_relay_nets=''/g" \
    -e "s/^dc_hide_mailname=.*/dc_hide_mailname='true'/g" \
    -e "s/^dc_mailname_in_oh=.*/dc_mailname_in_oh='true'/g" \
    -e "s/^dc_localdelivery=.*/dc_localdelivery='mail_spool'/g" \
    /etc/exim4/update-exim4.conf.conf
#
# debconf question exim4/dc_postmaster
sed -i -e "s/^root: .*/root: sysmsg+openstack.$(hostname)@infcs.de/g" /etc/aliases
#
# debconf question exim4/mailname
hostname --fqdn > /etc/mailname
#
# Synchronize debconf database with exim4-config's config which will help during
# package updates because debconf will not complain about config changes
cat << EOF | debconf-set-selections
exim4-config   exim4/dc_eximconfig_configtype   select  mail sent by smarthost; no local mail
exim4-config   exim4/dc_local_interfaces        string  127.0.0.1 ; ::1
exim4-config   exim4/dc_minimaldns              boolean false
exim4-config   exim4/dc_other_hostnames         string  
exim4-config   exim4/dc_postmaster              string  sysmsg+openstack.$(hostname)@infcs.de
exim4-config   exim4/dc_readhost                string  $(hostname --fqdn)
exim4-config   exim4/dc_smarthost               string  smtp.infcs.de
exim4-config   exim4/mailname                   string  $(hostname --fqdn)
exim4-config   exim4/use_split_config           boolean false
EOF
dpkg-reconfigure -f noninteractive exim4-config

# Set email addresses used for outgoing mails, e.g. set from address in
# outgoing mails from root to operator+_HOSTNAME_@mail.inf.h-brs.de
echo "root: operator+$(hostname)@mail.inf.h-brs.de" >> /etc/email-addresses
# or e.g.
echo "root: sysmsg+openstack.$(hostname)@infcs.de" >> /etc/email-addresses


# Redirect all mails, which are send to root, to _EMAIL_RECIPIENT_
vi /etc/aliases
# Change
#  root: ...
# to
#  root: _EMAIL_RECIPIENT_

# Repeat changes to /etc/email-addresses and /etc/aliases for each local users which should
# be able to receive local mails and get them forwarded to _EMAIL_RECIPIENT_, e.g.
echo "_USER_: operator+$(hostname)@mail.inf.h-brs.de" >> /etc/email-addresses
echo "_USER_: _EMAIL_RECIPIENT_" >> /etc/aliases

systemctl restart exim4.service
# or
service exim4 restart

echo "Exim4 test mail from $(hostname --fqdn) at $(date '+%Y%m%d%H%M%S')" | mail -s "exim4 test" root

# NOTE: You do NOT need to setup operator+_HOSTNAME_@mail.inf.h-brs.de, because this is just
#       the email address that your exim4 uses to set the from address in outgoing emails.

# NOTE: By default, mails send to operator+_HOSTNAME_@mail.inf.h-brs.de will end up at your administrator's mailbox, 
#       so e.g. Steffen Kaiser and Christoph Neerfeld will receive them.
