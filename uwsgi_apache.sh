#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup uWSGI with Apache2
#
# NOTE: It is expected that Apache2 is already installed and configured.

sudo -s
apt-get update
apt-get install python3 uwsgi uwsgi-plugin-python3 libapache2-mod-uwsgi

a2enmod uwsgi

cat << EOF > /etc/apache2/conf-available/uwsgi.conf
<IfModule mod_uwsgi.c>
    <Location /demo>
        Options FollowSymLinks Indexes
        SetHandler uwsgi-handler
        uWSGISocket /run/uwsgi/app/demo/socket
    </Location>
</IfModule>
EOF

(cd /etc/apache2/conf-enabled/ && ln -s ../conf-available/uwsgi.conf uwsgi.conf)

service apache2 restart

cat << EOF | unexpand --first-only --tabs=8 > /etc/uwsgi/apps-available/demo.ini
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

ln -s /etc/uwsgi/apps-available/demo.ini /etc/uwsgi/apps-enabled/demo.ini

mkdir /srv/wsgi_demo/

cat << EOF | unexpand --first-only --tabs=4 > /srv/wsgi_demo/wsgi_entry.py

def application(env, start_response):
    start_response('200 OK', [('Content-Type','text/html')])
    return [b"Hello World"]

EOF

service uwsgi restart

# Open your browser and navigate to your webserver's address, e.g. http://localhost/demo

exit # the end
