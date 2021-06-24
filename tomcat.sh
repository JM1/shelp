#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup Tomcat 7
#

sudo -s
aptitude install tomcat7 tomcat7-admin tomcat7-docs

vi /etc/tomcat7/server.xml

# Listen to localhost only and redirect HTTP to HTTPs
#
# Change ...
#    <Connector port="8080" protocol="HTTP/1.1"
#               connectionTimeout="20000"
#               URIEncoding="UTF-8"
#               redirectPort="8443" />
# ... to ...
#    <Connector port="8080" protocol="HTTP/1.1"
#               connectionTimeout="20000"
#               URIEncoding="UTF-8"
#               address="localhost"
#               redirectPort="8443" />

# Enable HTTPs / SSL encryption
#
# Change...
#    <Connector port="8443" protocol="org.apache.coyote.http11.Http11Protocol"
#               maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
#               clientAuth="false" sslProtocol="TLS" />
# ...to ...
#    <Connector port="8443" protocol="org.apache.coyote.http11.Http11Protocol"
#               maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
#               clientAuth="false" sslProtocol="TLS"
#               address="localhost"
#               ciphers="SSL_RSA_WITH_RC4_128_SHA"
#               keystoreFile="${user.home}/.keystore"
#               keystorePass="ADD_YOUR_KEYSTORE_PASSWORD_HERE" />
#
# TODO: You might want to set option 'ciphers' to a stronger algorithm and get rid of RC4!

cat << 'EOF' | patch /etc/tomcat7/web.xml
--- web.xml.orig        2016-02-06 14:53:06.099534584 +0100
+++ web.xml     2016-02-06 14:52:38.091034862 +0100
@@ -21,6 +21,17 @@
                       http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
   version="3.0">
 
+  <!-- Quelle: http://tomcat.10.n6.nabble.com/What-is-the-right-way-to-redirect-http-to-https-with-tomcat-7-td2123711.html -->
+  <security-constraint>
+    <web-resource-collection>
+      <web-resource-name>Everything is https</web-resource-name>
+      <url-pattern>/*</url-pattern>
+    </web-resource-collection>
+    <user-data-constraint>
+      <transport-guarantee>CONFIDENTIAL</transport-guarantee>
+    </user-data-constraint>
+  </security-constraint> 
+
   <!-- ======================== Introduction ============================== -->
   <!-- This document defines default values for *all* web applications      -->
   <!-- loaded into this instance of Tomcat.  As each application is         -->
EOF

vi /etc/tomcat7/tomcat-users.xml
# For example add these nodes as children to xml tag <tomcat-users>:
#
#  <role rolename="admin-gui"/>
#  <role rolename="manager-gui" />
#  <user username="ADD_YOUR_USERNAME_HERE" password="ADD_YOUR_PASSWORD_HERE" roles="standard,manager-gui,admin-gui" />

vi /etc/default/tomcat7
# Increase usable memory by uncommenting line beginning with ...
JAVA_OPTS="-Djava.awt.headless=true -Xmx512m -XX:+UseConcMarkSweepGC"
# ... and enable debugging functionality by uncommenting line beginning with
JAVA_OPTS="${JAVA_OPTS} -Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n"

exit # the end
