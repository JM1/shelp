#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Set up HTTPs/SSL encryption for Apache2
#
# Ref.:
#  https://doc.owncloud.org/server/9.0/admin_manual/configuration_server/harden_server.html
#  https://mozilla.github.io/server-side-tls/ssl-config-generator/

# Follow e.g. openssl_ca_guide.sh to create self-signed SSL Certificates
# or follow apache_letsencrypt.sh for Let’s Encrypt certificates.

cp -raiv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.orig

dash # bash interprets tabs which causes problems with patch
cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/sites-available/default-ssl.conf.orig	2015-10-24 10:37:19.000000000 +0200
+++ /etc/apache2/sites-available/default-ssl.conf	2016-06-28 11:24:26.392000000 +0200
@@ -29,8 +29,8 @@
 		#   /usr/share/doc/apache2/README.Debian.gz for more info.
 		#   If both key and certificate are stored in the same file, only the
 		#   SSLCertificateFile directive is needed.
-		SSLCertificateFile	/etc/ssl/certs/ssl-cert-snakeoil.pem
-		SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
+		SSLCertificateFile    /etc/ssl/certs/apache2.crt
+		SSLCertificateKeyFile /etc/ssl/private/apache2.key
 
 		#   Server Certificate Chain:
 		#   Point SSLCertificateChainFile at a file containing the
@@ -49,7 +49,7 @@
 		#		 to point to the certificate files. Use the provided
 		#		 Makefile to update the hash symlinks after changes.
 		#SSLCACertificatePath /etc/ssl/certs/
-		#SSLCACertificateFile /etc/apache2/ssl.crt/ca-bundle.crt
+		SSLCACertificateFile /etc/ssl/certs/jmca.crt
 
 		#   Certificate Revocation Lists (CRL):
 		#   Set the CA revocation path where to find CA CRLs for client
@@ -59,7 +59,7 @@
 		#		 to point to the certificate files. Use the provided
 		#		 Makefile to update the hash symlinks after changes.
 		#SSLCARevocationPath /etc/apache2/ssl.crl/
-		#SSLCARevocationFile /etc/apache2/ssl.crl/ca-bundle.crl
+		SSLCARevocationFile /etc/ssl/certs/jmca.crl
 
 		#   Client Authentication (Type):
 		#   Client certificate verification type and depth.  Types are

EOF


# Enable HTTP Strict Transport Security
cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/sites-available/default-ssl.conf.orig	2015-10-24 10:37:19.000000000 +0200
+++ /etc/apache2/sites-available/default-ssl.conf	2016-06-28 10:28:15.980000000 +0200
@@ -130,6 +130,10 @@
 		# MSIE 7 and newer should be able to use keepalive
 		BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
 
+		# Enable HTTP Strict Transport Security
+		<IfModule mod_headers.c>
+			Header always set Strict-Transport-Security "max-age=15768000; includeSubDomains; preload"
+		</IfModule>
 	</VirtualHost>
 </IfModule>
 
EOF

a2ensite default-ssl.conf

cat << 'EOF' >> /etc/apache2/conf-available/ssl.conf
# 2016 Jakob Meng, <jakobmeng@web.de>
# Generated using Mozilla SSL Configuration Generator
# Profile: Apache / Modern / HSTS Enabled
# Ref.: https://mozilla.github.io/server-side-tls/ssl-config-generator/
<IfModule mod_ssl.c>

	# modern configuration, tweak to your needs
	SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
	SSLCipherSuite          ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256
	SSLHonorCipherOrder     on
	SSLCompression          off
	# SSLSessionTickets requires Apache2 2.4.12 or later.
	# SSLSessionTickets       off

	# OCSP Stapling, only in httpd 2.3.3 and later
	SSLUseStapling          on
	SSLStaplingResponderTimeout 5
	SSLStaplingReturnResponderErrors off
	SSLStaplingCache        shmcb:/var/run/ocsp(128000)

</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF

a2enconf ssl
a2enmod ssl
a2enmod headers # Required for HTTP Strict Transport Security

# Redirect Request to SSL using virtual hosts
# Ref.: https://wiki.apache.org/httpd/RedirectSSL
cat << 'EOF' | patch -p0 -d /
--- /etc/apache2/sites-available/000-default.conf.orig	2015-10-24 10:37:19.000000000 +0200
+++ /etc/apache2/sites-available/000-default.conf	2019-06-24 10:06:45.678393687 +0200
@@ -26,6 +26,10 @@
 	# following line enables the CGI configuration for this host only
 	# after it has been globally disabled with "a2disconf".
 	#Include conf-available/serve-cgi-bin.conf
+
+	# Redirect Request to SSL using virtual hosts
+	# Ref.: https://wiki.apache.org/httpd/RedirectSSL	
+	Redirect / https://cloud.tree.h-brs.de/
 </VirtualHost>
 
 # vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF
a2ensite 000-default.conf

# Redirect Request to SSL using rewrite rules (not recommended behavior!)
# Ref.: https://wiki.apache.org/httpd/RewriteHTTPToHTTPS
cat << 'EOF' >> /etc/apache2/conf-available/redirect_http_to_https.conf
# 2016 Jakob Meng, <jakobmeng@web.de>
# Redirect all unencrypted traffic to HTTPS
# References:
#  https://wiki.apache.org/httpd/RewriteHTTPToHTTPS
#  https://wiki.apache.org/httpd/RedirectSSL
#  https://doc.owncloud.org/server/9.0/admin_manual/configuration_server/harden_server.html

RewriteEngine On
# This will enable the Rewrite capabilities

RewriteCond %{HTTPS} !=on
# This checks to make sure the connection is not already HTTPS

RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
# This rule will redirect users from their original location, to the same location but using HTTPS.
# i.e.  http://www.example.com/foo/ to https://www.example.com/foo/
# The leading slash is made optional so that this will work either in httpd.conf
# or .htaccess context

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

EOF
a2enconf redirect_http_to_https

exit

systemctl reload apache2

# Once the configuration is working as intended, a permanent redirection can be considered.
# This avoids caching issues by most browsers while testing. The directive
#  Redirect / https://cloud.tree.h-brs.de/
# in /etc/apache2/sites-available/000-default.conf would then become
#  Redirect permanent / https://cloud.tree.h-brs.de/
systemctl reload apache2

exit # the end
