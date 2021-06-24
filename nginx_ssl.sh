#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup nginx with authentication via ssl client certificates
#

sudo -s

# Create certificates as described in openssl_ca_guide.sh

cp -ip YOUR_CA_CERTIFICATE.pem /etc/ssl/certs/rpi-ca-cert.pem
cp -ip YOUR_SERVER_CERTIFICATE.pem /etc/ssl/certs/rpi-ssl-cert.pem
cp -ip YOUR_CA_REVOCATION_LIST.crl /etc/ssl/private/rpi-ca-cert.crl
cp -ip YOUR_SERVER_PRIVATE_KEY.key /etc/ssl/private/rpi-ssl-cert.key

chown root.root /etc/ssl/certs/rpi-ca-cert.pem
chown root.root /etc/ssl/certs/rpi-ssl-cert.pem
chown root.root /etc/ssl/private/rpi-ca-cert.crl
chown root.root /etc/ssl/private/rpi-ssl-cert.key

chmod a-rwx,u+rw /etc/ssl/private/rpi-ca-cert.crl
chmod a-rwx,u+rw /etc/ssl/private/rpi-ssl-cert.key

apt-get update
apt-get install nginx nginx-doc

rm /etc/nginx/sites-enabled/default

cat << EOF | unexpand --first-only --tabs=8 > /etc/nginx/sites-available/rpi
##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# http://wiki.nginx.org/Pitfalls
# http://wiki.nginx.org/QuickStart
# http://wiki.nginx.org/Configuration
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##

server {
        listen 80 default_server;
        listen [::]:80 default_server;
        return 301 https://\$host\$request_uri;
}

server {
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        ssl_certificate /etc/ssl/certs/rpi-ssl-cert.pem;
        ssl_certificate_key /etc/ssl/private/rpi-ssl-cert.key;
        ssl_client_certificate /etc/ssl/certs/rpi-ca-cert.pem;
        ssl_crl /etc/ssl/private/rpi-ca-cert.crl;
        ssl_verify_client on;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";

        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;

        include snippets/rpi-*.conf;

        server_name _;

        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files \$uri \$uri/ =404;
        }

        # deny access to .htaccess files, if Apache's document root concurs with nginx's one
        location ~ /\.ht {
                deny all;
        }
}

EOF

ln -s /etc/nginx/sites-available/rpi /etc/nginx/sites-enabled/rpi

service nginx restart

# Add client certificate to your browser as described here:
#  http://www.binarytides.com/client-side-ssl-certificates-firefox-chrome/
# Restart your browser and open your webserver's address

exit # the end
