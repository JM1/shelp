#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Install GitLab in VM with Debian 8 (Jessie)
#

# Follow libvirt.sh to create a virtual machine with Debian 8 (Jessie)
# Follow debian_setup.sh to install Debian 8 (Jessie)
# Follow exim.sh to configure Exim for mail support
# Follow apt_unattended_upgrades.sh to enable unattended upgrades for APT

_USER_=root
_HOSTNAME_=ux-2g02.inf.fh-bonn-rhein-sieg.de
_EMAIL_RECIPIENT_='jakob.meng@h-brs.de'

########################################
#
# Base installation
#

apt-get install apt-transport-https

cat << 'EOF' > /etc/apt/sources.list.d/gitlab_gitlab-ce.list
deb https://packages.gitlab.com/gitlab/gitlab-ce/debian/ jessie main

#deb-src https://packages.gitlab.com/gitlab/gitlab-ce/debian/ jessie main
EOF

wget -nv https://packages.gitlab.com/gpg.key -O /etc/apt/trusted.gpg.d/packages.gitlab.com.gpg
apt-get update

iptables -A INPUT -i eth0 -p tcp --dport http -j DROP
iptables -A INPUT -i eth0 -p tcp --dport https -j DROP
iptables -A INPUT -i eth0 -p udp --dport http -j DROP
iptables -A INPUT -i eth0 -p udp --dport https -j DROP

apt-get install gitlab-ce haveged

########################################
#
# New setup (no restore from backup)
#

sed -i "s/http:\/\/${_HOSTNAME_}/https:\/\/${_HOSTNAME_}/g" /etc/gitlab/gitlab.rb

mkdir -p /etc/gitlab/ssl
chmod 700 /etc/gitlab/ssl
cd /etc/gitlab/ssl
openssl req -x509 -newkey rsa:4096 -nodes -keyout "$(hostname --fqdn).key" -out "$(hostname --fqdn).crt" -days 3650
# Use your hostname as Common Name (CN)
chmod g-rwx,o-rwx *.key
chmod a-w *
openssl x509 -noout -fingerprint -in "$(hostname --fqdn).crt" # Remember the fingerprint!

# Check connectivity to LDAP server with:
#  openssl s_client -connect ldap.inf.fh-brs.de:636  2>/dev/null < /dev/null

# Retrieve certificate of internal H-BRS CA
wget https://ux-2s18.inf.h-brs.de/faq/folder/FB-Inf_FH-BRS_RootCert2008.import -O /etc/gitlab/trusted-certs/FB-Inf_FH-BRS_RootCert2008.pem
chmod a-wx /etc/gitlab/trusted-certs/FB-Inf_FH-BRS_RootCert2008.pem

# Replace certificate of internal H-BRS CA once ldap.inf.fh-bonn-rhein-sieg.de has been migrated to ldap.inf.h-brs.de
#wget https://ux-2s18.inf.h-brs.de/faq/folder/FB02_RCA_2017-cacert.import -O /etc/gitlab/trusted-certs/FB02_RCA_2017-cacert.pem
#chmod a-wx /etc/gitlab/trusted-certs/FB02_RCA_2017-cacert.pem

# Adapt gitlab_email_reply_to to your hostname.
cat << 'EOF' >> /etc/gitlab/gitlab.rb

####################
### H-BRS Config ###
####################

gitlab_rails['gitlab_default_can_create_group'] = false

# Reference: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md
nginx['listen_addresses'] = ['127.0.0.1'] # Change your root password first before removing this line.
nginx['redirect_http_to_https'] = true

# Disabling auto-configuration 
# Reference: https://docs.gitlab.com/omnibus/settings/ssl.html#disabling-auto-configuration
letsencrypt['enable'] = false

# Reference: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/integration/ldap.md
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
  main:
    label: 'H-BRS'
    host: 'ldap.inf.fh-bonn-rhein-sieg.de'
    port: 636
    uid: 'uid'
    method: 'ssl'
    bind_dn: ''
    password: ''
    timeout: 10
    active_directory: false
    allow_username_or_email_login: false
    block_auto_created_users: true
    base: 'dc=fh-bonn-rhein-sieg,dc=de'
    user_filter: ''
    ca_file: '/etc/gitlab/trusted-certs/FB-Inf_FH-BRS_RootCert2008.pem'
    #ca_file: '/etc/gitlab/trusted-certs/FB02_RCA_2017-cacert.pem'
EOS
# NOTE: GitLab does check the server certificate since version 10.0, in prior versions man-in-the-middle attacks are possible!
# References: 
#  https://about.gitlab.com/2017/09/22/gitlab-10-0-released/#ldap-config-%22verify_certificates%22-defaults-to-secure
#  https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/integration/ldap.md
#  http://feedback.gitlab.com/forums/176466-deprecated-feedback-forum/suggestions/5346585-ldap-start-tls-server-certificate-validation
#  http://www.rubydoc.info/github/ruby-ldap/ruby-net-ldap/Net/LDAP:encryption


# References:
#  https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/smtp.md
#  https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/common_installation_problems/README.md#emails-are-not-being-delivered
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.inf.fh-bonn-rhein-sieg.de"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = 'jakob.meng@h-brs.de'
gitlab_rails['gitlab_email_reply_to'] = 'operator+ux-2g02@mail.inf.fh-bonn-rhein-sieg.de'

EOF

gitlab-ctl reconfigure

exit

ssh -L 60443:localhost:443 -L 60080:localhost:80 _USER_@_HOSTNAME_
# Open https://localhost:60443/ in your client's browser
# Choose Realm "Standard" and login with user 'root' and password '5iveL!fe'.
# Change your root password!
# Go to "Admin Area" (Top) 
# => "Settings" (Lower Left) 
#  => Scroll down to "Account and Limit Settings"
#  => Uncheck 'Gravatar enabled' and 'Twitter enabled'
#  => Set 'Default projects limit' to '0' (Zero)
#  => Scroll down to "Sign-in Restrictions" 
#  => Uncheck 'Sign-up enabled' 
#  => Press 'Save'
# Logout as root.
#
# Choose Realm "H-BRS" domain and login with your ldap user account, e.g. 'jmeng2m' and your password.
# You'll get a message that an admin must unblock you first.
#
# Choose Realm "Standard" and login with user 'root' and your new root password.
# Go to "Admin Area" (Top) 
# => "Users" (Upper Left)
#  => Tab "Blocked"
#  => Unblock your LDAP User
#  => Tab "Active"
#  => Click on your LDAP User
#  => Press "Edit" (Top Right)
#  => Check "Admin"
#  => Press "Save changes"
# Logout as root.
#
# Choose Realm "H-BRS" domain and login with your ldap user account, e.g. 'jmeng2m' and your password.
# Go to "Admin Area" (Top) 
# => "Users" (Upper Left)
#  => Tab "Active"
#  => Block user "Administrator"
# Logout.
exit

vi /etc/gitlab/gitlab.rb 
# Remove or comment this line:
#  nginx['listen_addresses'] = ['127.0.0.1'] # Change your root password first before removing this line.
gitlab-ctl reconfigure

iptables -F INPUT

exit # the end
