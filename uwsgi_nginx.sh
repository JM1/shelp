#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup uWSGI with nginx
#

# First setup nginx as described above
# in chapter "Setup nginx with authentication via ssl client certificates"

sudo -s
apt-get update
apt-get install python3 uwsgi uwsgi-plugin-python3

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

upstream uwsgi_socket {
        server unix:///run/uwsgi/app/rpi/socket;
}

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

        charset utf-8;

        location / {
                uwsgi_pass uwsgi_socket;
                include /etc/nginx/uwsgi_params;
        }
}

EOF

service nginx restart

cat << EOF | unexpand --first-only --tabs=8 > /etc/uwsgi/apps-available/rpi.ini
# 
# See /usr/share/uwsgi/conf/default.ini for default options being inherited.
# 
[uwsgi]

plugins = python3

# Base application directory
chdir   = /srv/wsgi_demo/

# module = [wsgi_module_name]:[application_callable_name]
module  = wsgi_entry:application

EOF

ln -s /etc/uwsgi/apps-available/rpi.ini /etc/uwsgi/apps-enabled/rpi.ini

mkdir /srv/wsgi_demo/

cat << EOF | unexpand --first-only --tabs=4 > /srv/wsgi_demo/wsgi_entry.py

def application(env, start_response):
    start_response('200 OK', [('Content-Type','text/html')])
    return [b"Hello World"]

EOF

service uwsgi restart

# Open your browser and navigate to your webserver's address

exit # the end
