#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Let’s Encrypt for Apache2
#
# Ref.:
#  https://wiki.debian.org/LetsEncrypt
#  https://certbot.eff.org/lets-encrypt/debianstretch-apache.html

# Suppose saloon.wildwildwest.com is your fqdn.

# On Debian 9 (Stretch)
# First enable debian's backports repository (apt_repository.sh)
apt-get install certbot python-certbot-apache -t stretch-backports

# On Debian 10 (Buster)
apt-get install certbot python-certbot-apache

certbot certonly --apache # write down certificate paths

# Test automatic renewal
certbot renew --dry-run

# setup certificate paths in Apache2
vi /etc/apache2/sites-available/default-ssl.conf

# example
cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/sites-available/default-ssl.conf.bak1	2019-05-07 21:04:08.666202047 +0200
+++ /etc/apache2/sites-available/default-ssl.conf	2019-06-24 10:32:54.637317669 +0200
@@ -19,6 +19,7 @@
 		# following line enables the CGI configuration for this host only
 		# after it has been globally disabled with "a2disconf".
 		#Include conf-available/serve-cgi-bin.conf
+                Include /etc/letsencrypt/options-ssl-apache.conf
 
 		#   SSL Engine Switch:
 		#   Enable/Disable SSL for this virtual host.
@@ -29,8 +30,8 @@
 		#   /usr/share/doc/apache2/README.Debian.gz for more info.
 		#   If both key and certificate are stored in the same file, only the
 		#   SSLCertificateFile directive is needed.
-		SSLCertificateFile	/etc/ssl/certs/apache2.pem
-		SSLCertificateKeyFile /etc/ssl/private/apache2.key
+		SSLCertificateFile    /etc/letsencrypt/live/saloon.wildwildwest.com/fullchain.pem
+		SSLCertificateKeyFile /etc/letsencrypt/live/saloon.wildwildwest.com/privkey.pem
 
 		#   Server Certificate Chain:
 		#   Point SSLCertificateChainFile at a file containing the
@@ -40,7 +41,6 @@
 		#   when the CA certificates are directly appended to the server
 		#   certificate for convinience.
 		#SSLCertificateChainFile /etc/apache2/ssl.crt/server-ca.crt
-		SSLCertificateChainFile /etc/ssl/certs/Hochschule_Bonn-Rhein-Sieg_CA_Zertifikat.crt
 
 		#   Certificate Authority (CA):
 		#   Set the CA certificate verification path where to find CA

EOF

# Confirm that Certbot worked, e.g. via https://www.ssllabs.com/ssltest/

####################
# Renew certificate for changed hostname

# Change hostname
reboot

certbot delete --cert-name saloon.wildwildwest.com
a2dissite default-ssl.conf
systemctl restart apache2.service

certbot certonly --apache # enter all valid domain names

a2ensite default-ssl.conf
systemctl restart apache2.service
certbot renew --dry-run

reboot
