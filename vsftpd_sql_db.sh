#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# vsftpd with user authentication through MySQL / MariaDB on Debian 8 (Jessie) or Debian 9 (Stretch)
#

apt-get install vsftpd

cat << 'EOF' | patch -p0 -d /
--- /etc/vsftpd.conf.orig	2016-09-21 10:38:42.000000000 +0200
+++ /etc/vsftpd.conf	2018-01-08 13:27:57.068209878 +0100
@@ -11,7 +11,8 @@
 #
 # Run standalone?  vsftpd can run either from an inetd or as a standalone
 # daemon started from an initscript.
-listen=NO
+#listen=NO
+listen=YES
 #
 # This directive enables listening on IPv6 sockets. By default, listening
 # on the IPv6 "any" address (::) will accept connections from both IPv6
@@ -19,7 +20,7 @@
 # sockets. If you want that (perhaps because you want to listen on specific
 # addresses) then you must run two copies of vsftpd with two configuration
 # files.
-listen_ipv6=YES
+#listen_ipv6=YES
 #
 # Allow anonymous FTP? (Disabled by default).
 anonymous_enable=NO
@@ -101,6 +102,7 @@
 #
 # You may fully customise the login banner string:
 #ftpd_banner=Welcome to blah FTP service.
+ftpd_banner=Private FTP Site. Your are not allowed to enter!
 #
 # You may specify a file of disallowed anonymous e-mail addresses. Apparently
 # useful for combatting certain DoS attacks.
@@ -111,7 +113,7 @@
 # You may restrict local users to their home directories.  See the FAQ for
 # the possible risks in this before using chroot_local_user or
 # chroot_list_enable below.
-#chroot_local_user=YES
+chroot_local_user=YES
 #
 # You may specify an explicit list of local users to chroot() to their home
 # directory. If chroot_local_user is YES, then this list becomes a list of
@@ -146,10 +148,32 @@
 #
 # This option specifies the location of the RSA certificate to use for SSL
 # encrypted connections.
-rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
-rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
-ssl_enable=NO
+#rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
+#rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
+#ssl_enable=NO
 
 #
 # Uncomment this to indicate that vsftpd use a utf8 filesystem.
-#utf8_filesystem=YES
+utf8_filesystem=YES
+
+rsa_cert_file=/etc/ssl/certs/vsftpd.crt
+rsa_private_key_file=/etc/ssl/private/vsftpd.key
+
+guest_enable=YES
+guest_username=ftp
+user_config_dir=/etc/vsftpd_users
+user_sub_token=$USER
+local_root=/home/ftp/$USER
+
+#virtual_use_local_privs=YES
+#hide_ids=YES
+
+ssl_enable=YES
+allow_anon_ssl=NO
+force_local_data_ssl=NO
+force_local_logins_ssl=NO
+ssl_tlsv1=YES
+ssl_sslv2=NO
+ssl_sslv3=NO
+
+ssl_ciphers=HIGH

EOF

# NOTE: On Debian 8 (Jessie) remove option utf8_filesystem
cat << 'EOF' | patch -p0 -d /
--- /etc/vsftpd.conf.bak3       2016-02-06 22:26:04.384189402 +0100
+++ /etc/vsftpd.conf    2018-01-08 13:27:57.068209878 +0100
@@ -152,10 +152,6 @@
 #rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
 #ssl_enable=NO
 
-#
-# Uncomment this to indicate that vsftpd use a utf8 filesystem.
-utf8_filesystem=YES
-
 rsa_cert_file=/etc/ssl/certs/vsftpd.crt
 rsa_private_key_file=/etc/ssl/private/vsftpd.key
 
EOF

# NOTE: Complete /etc/vsftpd.conf for Debian 9 (Stretch) looks like this:
cat << 'EOF' > /dev/null
# Example config file /etc/vsftpd.conf
#
# The default compiled in settings are fairly paranoid. This sample file
# loosens things up a bit, to make the ftp daemon more usable.
# Please see vsftpd.conf.5 for all compiled in defaults.
#
# READ THIS: This example file is NOT an exhaustive list of vsftpd options.
# Please read the vsftpd.conf.5 manual page to get a full idea of vsftpd's
# capabilities.
#
#
# Run standalone?  vsftpd can run either from an inetd or as a standalone
# daemon started from an initscript.
#listen=NO
listen=YES
#
# This directive enables listening on IPv6 sockets. By default, listening
# on the IPv6 "any" address (::) will accept connections from both IPv6
# and IPv4 clients. It is not necessary to listen on *both* IPv4 and IPv6
# sockets. If you want that (perhaps because you want to listen on specific
# addresses) then you must run two copies of vsftpd with two configuration
# files.
#listen_ipv6=YES
#
# Allow anonymous FTP? (Disabled by default).
anonymous_enable=NO
#
# Uncomment this to allow local users to log in.
local_enable=YES
#
# Uncomment this to enable any form of FTP write command.
#write_enable=YES
#
# Default umask for local users is 077. You may wish to change this to 022,
# if your users expect that (022 is used by most other ftpd's)
#local_umask=022
#
# Uncomment this to allow the anonymous FTP user to upload files. This only
# has an effect if the above global write enable is activated. Also, you will
# obviously need to create a directory writable by the FTP user.
#anon_upload_enable=YES
#
# Uncomment this if you want the anonymous FTP user to be able to create
# new directories.
#anon_mkdir_write_enable=YES
#
# Activate directory messages - messages given to remote users when they
# go into a certain directory.
dirmessage_enable=YES
#
# If enabled, vsftpd will display directory listings with the time
# in  your  local  time  zone.  The default is to display GMT. The
# times returned by the MDTM FTP command are also affected by this
# option.
use_localtime=YES
#
# Activate logging of uploads/downloads.
xferlog_enable=YES
#
# Make sure PORT transfer connections originate from port 20 (ftp-data).
connect_from_port_20=YES
#
# If you want, you can arrange for uploaded anonymous files to be owned by
# a different user. Note! Using "root" for uploaded files is not
# recommended!
#chown_uploads=YES
#chown_username=whoever
#
# You may override where the log file goes if you like. The default is shown
# below.
#xferlog_file=/var/log/vsftpd.log
#
# If you want, you can have your log file in standard ftpd xferlog format.
# Note that the default log file location is /var/log/xferlog in this case.
#xferlog_std_format=YES
#
# You may change the default value for timing out an idle session.
#idle_session_timeout=600
#
# You may change the default value for timing out a data connection.
#data_connection_timeout=120
#
# It is recommended that you define on your system a unique user which the
# ftp server can use as a totally isolated and unprivileged user.
#nopriv_user=ftpsecure
#
# Enable this and the server will recognise asynchronous ABOR requests. Not
# recommended for security (the code is non-trivial). Not enabling it,
# however, may confuse older FTP clients.
#async_abor_enable=YES
#
# By default the server will pretend to allow ASCII mode but in fact ignore
# the request. Turn on the below options to have the server actually do ASCII
# mangling on files when in ASCII mode.
# Beware that on some FTP servers, ASCII support allows a denial of service
# attack (DoS) via the command "SIZE /big/file" in ASCII mode. vsftpd
# predicted this attack and has always been safe, reporting the size of the
# raw file.
# ASCII mangling is a horrible feature of the protocol.
#ascii_upload_enable=YES
#ascii_download_enable=YES
#
# You may fully customise the login banner string:
#ftpd_banner=Welcome to blah FTP service.
ftpd_banner=Private FTP Site. Your are not allowed to enter!
#
# You may specify a file of disallowed anonymous e-mail addresses. Apparently
# useful for combatting certain DoS attacks.
#deny_email_enable=YES
# (default follows)
#banned_email_file=/etc/vsftpd.banned_emails
#
# You may restrict local users to their home directories.  See the FAQ for
# the possible risks in this before using chroot_local_user or
# chroot_list_enable below.
chroot_local_user=YES
#
# You may specify an explicit list of local users to chroot() to their home
# directory. If chroot_local_user is YES, then this list becomes a list of
# users to NOT chroot().
# (Warning! chroot'ing can be very dangerous. If using chroot, make sure that
# the user does not have write access to the top level directory within the
# chroot)
#chroot_local_user=YES
#chroot_list_enable=YES
# (default follows)
#chroot_list_file=/etc/vsftpd.chroot_list
#
# You may activate the "-R" option to the builtin ls. This is disabled by
# default to avoid remote users being able to cause excessive I/O on large
# sites. However, some broken FTP clients such as "ncftp" and "mirror" assume
# the presence of the "-R" option, so there is a strong case for enabling it.
#ls_recurse_enable=YES
#
# Customization
#
# Some of vsftpd's settings don't fit the filesystem layout by
# default.
#
# This option should be the name of a directory which is empty.  Also, the
# directory should not be writable by the ftp user. This directory is used
# as a secure chroot() jail at times vsftpd does not require filesystem
# access.
secure_chroot_dir=/var/run/vsftpd/empty
#
# This string is the name of the PAM service vsftpd will use.
pam_service_name=vsftpd
#
# This option specifies the location of the RSA certificate to use for SSL
# encrypted connections.
#rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
#rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
#ssl_enable=NO

#
# Uncomment this to indicate that vsftpd use a utf8 filesystem.
utf8_filesystem=YES

rsa_cert_file=/etc/ssl/certs/vsftpd.crt
rsa_private_key_file=/etc/ssl/private/vsftpd.key

guest_enable=YES
guest_username=ftp
user_config_dir=/etc/vsftpd_users
user_sub_token=$USER
local_root=/home/ftp/$USER

#virtual_use_local_privs=YES
#hide_ids=YES

ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=NO
force_local_logins_ssl=NO
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO

ssl_ciphers=HIGH

EOF

cat << 'EOF' >> /etc/pam.d/vsftpd_mysql
auth required /lib/security/pam_mysql.so user=vsftpd passwd=ENTER_YOUR_DB_PASSWORD_HERE db=vsftpd table=users usercolumn=username passwdcolumn=password crypt=1 where=enabled=true sqllog=0
account required /lib/security/pam_mysql.so user=vsftpd passwd=ENTER_YOUR_DB_PASSWORD_HERE db=vsftpd table=users usercolumn=username passwdcolumn=password crypt=1 where=enabled=true sqllog=0
EOF

chmod 600 /etc/pam.d/vsftpd_mysql

# NOTE: Dumped with: mysqldump --lock-tables -h localhost -u root vsftpd -p > /tmp/vsftpd_userdb_example.sql
cat << 'EOF' > /tmp/vsftpd_userdb_example.sql
-- MySQL dump 10.16  Distrib 10.1.26-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: vsftpd
-- ------------------------------------------------------
-- Server version	10.1.26-MariaDB-0+deb9u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(250) NOT NULL,
  `password` varchar(250) NOT NULL,
  `enabled` bit(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (4,'dbox2','II57DIlXYjK9s','');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-04-08  8:24:16

EOF

mysql -u root vsftpd -p < /tmp/vsftpd_userdb_example.sql

rm /tmp/vsftpd_userdb_example.sql

mkdir /etc/vsftpd_users
chmod 755 /etc/vsftpd_users

cat << 'EOF' > /etc/vsftpd_users/dbox2
anon_world_readable_only=NO
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
anon_umask=011
local_umask=011

EOF

# Generate
#  /etc/ssl/certs/vsftpd.crt
#  /etc/ssl/private/vsftpd.key
# as described in openssl_ca_guide.sh

# (Optional) system user for vsftpd daemon (is set by default)
debconf vsftpd vsftpd/username ftp

mkdir -p /home/ftp/dbox2
chown -R ftp.nogroup /home/ftp
chmod -R 755 /home/ftp

service vsftpd restart

exit # the end
