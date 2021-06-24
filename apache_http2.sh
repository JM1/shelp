#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enable HTTP/2 module on Apache2
#
# Ref.:
#  https://localhorst.org/http-2-0-debian-9-apache-2-4-umstellung-auf-php-fpm/
#  https://linuxhostsupport.com/blog/how-to-set-up-apache-with-http-2-support-on-debian-9/
#  https://httpd.apache.org/docs/2.4/howto/http2.html

a2enmod http2

vi /etc/apache2/sites-enabled/default-ssl.conf
# Add:
#  <IfModule mod_ssl.c>
#  	<VirtualHost _default_:443>
#  		...
#  		
#  		# Enable HTTP/2 module in Apache
#  		Protocols h2 h2c http/1.1
#  	</VirtualHost>
#  </IfModule>

systemctl restart apache2

# Test HTTP/2 connection
curl -s -v --http2 https://cloud.tree.h-brs.de
# * Rebuilt URL to: https://cloud.tree.h-brs.de/
# *   Trying 194.95.66.170...
# * TCP_NODELAY set
# * Connected to cloud.tree.h-brs.de (194.95.66.170) port 443 (#0)
# * ALPN, offering h2
# * ALPN, offering http/1.1
# [...]
# * SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
# * ALPN, server accepted to use h2
# [...]
# * Using HTTP2, server supports multi-use
# * Connection state changed (HTTP/2 confirmed)
# * Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
# * Using Stream ID: 1 (easy handle 0x555a12168e80)
# > GET / HTTP/1.1
# > Host: cloud.tree.h-brs.de
# > User-Agent: curl/7.52.1
# > Accept: */*
# [...]

exit # the end
