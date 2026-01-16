#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Dovecot
#

################################################################################
# Dovecot on Debian 8 (Jessie) to Debian 13 (Trixie)
# Ref.:
# /usr/share/doc/dovecot-core/README.Debian
# https://doc.dovecot.org/2.3/configuration_manual/authentication/sql/
# https://doc.dovecot.org/2.3/configuration_manual/authentication/domain_lost/
# https://doc.dovecot.org/main/installation/upgrade/2.3-to-2.4.html
# https://doc.dovecot.org/2.4.1/core/summaries/settings.html

apt-get install dovecot-pop3d

cd /tmp/
cp -raiv /usr/share/dovecot/dovecot-openssl.cnf .
sed -i -e "s/@commonName@/$(hostname --fqdn)/g" dovecot-openssl.cnf
sed -i -e "s/@emailAddress@/root@$(hostname --fqdn)/g" dovecot-openssl.cnf
# rm /etc/dovecot/dovecot.pem /etc/dovecot/private/dovecot.pem
/usr/share/dovecot/mkcert.sh

[ -e /etc/dovecot/local.conf ] && \
  mv -i /etc/dovecot/local.conf /etc/dovecot/local.conf.$(date +%Y%m%d%H%M%S --reference /etc/dovecot/local.conf)

cat << 'EOF' >> /etc/dovecot/local.conf
# Dovecot configuration file
# 2011-2025 Jakob Meng, <jakobmeng@web.de>

EOF

# NOTE: Only required prior to Debian 13 (Trixie)
# Mail driver mbox is the default in Debian 13 (Trixie).
# Ref.: https://salsa.debian.org/debian/dovecot/-/blob/debian/1%252.4.1+dfsg1-6+deb13u2/debian/conf/conf.d/10-mail.conf
cat << EOF >> /etc/dovecot/local.conf
# Enable mail group temporarily for privileged operations. This is used with the INBOX when either its initial creation
# or dotlocking fails. Typically, this is set to mail to give access to /var/mail. Without this, errors will be raised
# when writing to /var/mail, e.g.:
#
# Jun  6 17:40:48 WildWildWest dovecot: pop3(johnwayne): Error: file_dotlock_create(/var/mail/johnwayne) failed: Permission denied (euid=1000(johnwayne) egid=1000(johnwayne) missing +w perm: /var/mail, euid is not dir owner) (set mail_privileged_group=mail)
#
# Ref.: https://doc.dovecot.org/settings/core/
mail_privileged_group = mail

mail_location = mbox:~/mail:INBOX=/var/mail/%n

EOF

# Optionally enable debug logging
# NOTE: On Debian 8 (Jessie) to Debian 12 (Bookworm)
cat << EOF >> /etc/dovecot/local.conf
# Debug logging
auth_debug = yes
auth_debug_passwords = yes

EOF
# NOTE: On Debian 13 (Trixie)
cat << EOF >> /etc/dovecot/local.conf
# Debug logging
log_debug = category=auth
auth_debug_passwords = yes

EOF

# Either listen to localhost only
cat << EOF >> /etc/dovecot/local.conf
# Listen to localhost only
listen = localhost

EOF
#
# or listen to hostname but then disable non-ssl connections
cat << EOF >> /etc/dovecot/local.conf
listen = $(hostname --fqdn)

# Disable non-ssl imap and non-ssl pop3
service imap-login {
  inet_listener imap {
    port = 0
  }
}

service pop3-login {
  inet_listener pop3 {
    port = 0
  }
}

EOF

# Verify that Dovecot is listening only on SSL ports
ss -tulpen | grep dovecot

# NOTE: Only required on Debian 8 (Jessie) or Debian 9 (Stretch).
# TLS is enabled by default in Dovecot since Debian 10 (Buster).
cat << 'EOF' >> /etc/dovecot/local.conf
# Enable SSL
ssl = yes
#ssl_cert = </etc/ssl/certs/dovecot.crt
#ssl_key = </etc/ssl/private/dovecot.key
#ssl_cert = </etc/dovecot/dovecot.pem
#ssl_key = </etc/dovecot/private/dovecot.pem
ssl_cert = </etc/dovecot/private/dovecot.pem
ssl_key = </etc/dovecot/private/dovecot.key

# Debugging SSL connections
#verbose_ssl = yes

EOF

# Disable PAM authentication
sed -i -e 's/^\!include auth-system\.conf\.ext/#\!include auth-system\.conf\.ext/g' /etc/dovecot/conf.d/10-auth.conf

chown root.dovecot /etc/dovecot/local.conf
chmod a-rwx,u+rw,g+r /etc/dovecot/local.conf
service dovecot restart

####################
# (Optional) Enable non-ssl pop3, but only on localhost
vi /etc/dovecot/local.conf
# Edit:
#  service pop3-login {
#    inet_listener pop3 {
#      port = 110
#      address = localhost
#    }
#  }

####################
# (Optional) Downgrade auth_mechanisms for Thunderbird when using option "Verschlüsseltes Passwort"
# WARNING: Use only on encrypted or local connections to dovecot!!!
cat << 'EOF' >> /etc/dovecot/local.conf
# ATTENTION:
# Only enabled because Thunderbird 31 has problems with self-signed certificates and dovecot listens to localhost only!
auth_mechanisms = plain cram-md5
EOF

####################
# (Optional) Authentication via Passwd-file
# Ref.:
# https://doc.dovecot.org/2.3/configuration_manual/authentication/passwd_file/
# https://doc.dovecot.org/2.4.1/core/config/auth/databases/passwd_file.html

# NOTE: On Debian 8 (Jessie) and Debian 9 (Stretch)
cat << 'EOF' >> /etc/dovecot/local.conf
# Authentication via Passwd-file
# Ref.: https://doc.dovecot.org/2.3/configuration_manual/authentication/passwd_file/

userdb {
  driver = passwd-file
  args = username_format=%n /etc/dovecot/users
}

passdb {
  driver = passwd-file
  args = username_format=%n /etc/dovecot/users
}
EOF

# NOTE: Since Debian 10 (Buster)
sed -i -e 's/^#\!include auth-passwdfile\.conf\.ext/\!include auth-passwdfile\.conf\.ext/g' conf.d/10-auth.conf

# NOTE: Since Debian 13 (Trixie)
# Either uncomment the passdb and userdb entries manually
vi /etc/dovecot/conf.d/auth-passwdfile.conf.ext
#
# or overwrite with
cp -raiv /etc/dovecot/conf.d/auth-passwdfile.conf.ext /etc/dovecot/conf.d/auth-passwdfile.conf.ext.orig
cat << 'EOF' >> /etc/dovecot/conf.d/auth-passwdfile.conf.ext
#
# Authentication for passwd-file users. Included from auth.conf.
#
# passwd-like file with specified location.
# <https://doc.dovecot.org/latest/core/config/auth/databases/passwd_file.html>

passdb passwd-file {
  default_password_scheme = crypt
  auth_username_format = %{user}
  passwd_file_path = /etc/dovecot/users
}

userdb passwd-file {
  auth_username_format = %{user}
  passwd_file_path = /etc/dovecot/users

#  fields {
#    quota_rule:default=*:storage=1G
#    home=/home/virtual/%{user}
#  }
}
EOF
diff -Naur /etc/dovecot/conf.d/auth-passwdfile.conf.ext.orig /etc/dovecot/conf.d/auth-passwdfile.conf.ext
rm -v /etc/dovecot/conf.d/auth-passwdfile.conf.ext.orig

# Generate password hash with doveadm
# Ref.: https://doc.dovecot.org/configuration_manual/authentication/password_schemes/#authentication-password-schemes
doveadm pw -s SHA512-CRYPT

# Create passwd file with username and password hash
# Ref.: https://doc.dovecot.org/2.3/configuration_manual/authentication/passwd_file/
cat << 'EOF' >> /etc/dovecot/users
user:{plain}secret:1000:1000:,,,:/home/user:/usr/sbin/nologin
EOF

chown root.dovecot /etc/dovecot/users
chmod u=rw,g=r,o= /etc/dovecot/users

systemctl restart dovecot.service
systemctl status dovecot.service

####################
# (Optional) Authentication via MySQL / MariaDB
# NOTE: These instructions apply to Dovecot versions 2.3 and earlier, up to Debian 12 (Bookworm).
# Ref.: https://doc.dovecot.org/2.3/configuration_manual/authentication/sql/
apt-get install dovecot-mysql

cat << 'EOF' >> /etc/dovecot/local.conf
# Authentication via MySQL / MariaDB
userdb {
  driver = sql
  args = /etc/dovecot/local-mysql.conf.ext
}

passdb {
  driver = sql
  args = /etc/dovecot/local-mysql.conf.ext
}

EOF

[ -e /etc/dovecot/local-mysql.conf.ext ] && \
  mv -i /etc/dovecot/local-mysql.conf.ext /etc/dovecot/local-mysql.conf.ext.$(date +%Y%m%d%H%M%S --reference /etc/dovecot/local-mysql.conf.ext)

SQL_DATABASE=dovecot
SQL_USERNAME=dovecot
SQL_PASSWORD=secret

[ ! -e /etc/dovecot/local-mysql.conf.ext ] && \
  cat << EOF >> /etc/dovecot/local-mysql.conf.ext
# 2011-2020 Jakob Meng, <jakobmeng@web.de>
# Compare with default configuration using this command: 
#  meld /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/local-mysql.conf.ext
#
# This file is commonly accessed via passdb {} or userdb {} section in
# conf.d/auth-sql.conf.ext

# This file is opened as root, so it should be owned by root and mode 0600.
#
# http://wiki2.dovecot.org/AuthDatabase/SQL
#
# For the sql passdb module, you'll need a database with a table that
# contains fields for at least the username and password. If you want to
# use the user@domain syntax, you might want to have a separate domain
# field as well.
#
# If your users all have the same uig/gid, and have predictable home
# directories, you can use the static userdb module to generate the home
# dir based on the username and domain. In this case, you won't need fields
# for home, uid, or gid in the database.
#
# If you prefer to use the sql userdb module, you'll want to add fields
# for home, uid, and gid. Here is an example table:
#
# CREATE TABLE users (
#     username VARCHAR(128) NOT NULL,
#     domain VARCHAR(128) NOT NULL,
#     password VARCHAR(64) NOT NULL,
#     home VARCHAR(255) NOT NULL,
#     uid INTEGER NOT NULL,
#     gid INTEGER NOT NULL,
#     active CHAR(1) DEFAULT 'Y' NOT NULL
# );

# Database driver: mysql, pgsql, sqlite
driver = mysql

# Database connection string. This is driver-specific setting.
#
# HA / round-robin load-balancing is supported by giving multiple host
# settings, like: host=sql1.host.org host=sql2.host.org
#
# pgsql:
#   For available options, see the PostgreSQL documentation for the
#   PQconnectdb function of libpq.
#   Use maxconns=n (default 5) to change how many connections Dovecot can
#   create to pgsql.
#
# mysql:
#   Basic options emulate PostgreSQL option names:
#     host, port, user, password, dbname
#
#   But also adds some new settings:
#     client_flags           - See MySQL manual
#     connect_timeout        - Connect timeout in seconds (default: 5)
#     read_timeout           - Read timeout in seconds (default: 30)
#     write_timeout          - Write timeout in seconds (default: 30)
#     ssl_ca, ssl_ca_path    - Set either one or both to enable SSL
#     ssl_cert, ssl_key      - For sending client-side certificates to server
#     ssl_cipher             - Set minimum allowed cipher security (default: HIGH)
#     ssl_verify_server_cert - Verify that the name in the server SSL certificate
#                              matches the host (default: no)
#     option_file            - Read options from the given file instead of
#                              the default my.cnf location
#     option_group           - Read options from the given group (default: client)
# 
#   You can connect to UNIX sockets by using host: host=/var/run/mysql.sock
#   Note that currently you can't use spaces in parameters.
#
# sqlite:
#   The path to the database file.
#
# Examples:
#   connect = host=192.168.1.1 dbname=users
#   connect = host=sql.example.com dbname=virtual user=virtual password=blarg
#   connect = /etc/dovecot/authdb.sqlite
#
#connect =
connect = host=localhost dbname=$(SQL_DATABASE) user=$(SQL_USERNAME) password=$(SQL_PASSWORD)

# Default password scheme.
#
# List of supported schemes is in
# http://wiki2.dovecot.org/Authentication/PasswordSchemes
#
#default_pass_scheme = MD5
default_pass_scheme = PLAIN

# passdb query to retrieve the password. It can return fields:
#   password - The user's password. This field must be returned.
#   user - user@domain from the database. Needed with case-insensitive lookups.
#   username and domain - An alternative way to represent the "user" field.
#
# The "user" field is often necessary with case-insensitive lookups to avoid
# e.g. "name" and "nAme" logins creating two different mail directories. If
# your user and domain names are in separate fields, you can return "username"
# and "domain" fields instead of "user".
#
# The query can also return other fields which have a special meaning, see
# http://wiki2.dovecot.org/PasswordDatabase/ExtraFields
#
# Commonly used available substitutions (see http://wiki2.dovecot.org/Variables
# for full list):
#   %u = entire user@domain
#   %n = user part of user@domain
#   %d = domain part of user@domain
# 
# Note that these can be used only as input to SQL query. If the query outputs
# any of these substitutions, they're not touched. Otherwise it would be
# difficult to have eg. usernames containing '%' characters.
#
# Example:
#   password_query = SELECT userid AS user, pw AS password \
#     FROM users WHERE userid = '%u' AND active = 'Y'
#
#password_query = \
#  SELECT username, domain, password \
#  FROM users WHERE username = '%n' AND domain = '%d'
password_query = SELECT userid AS username, domain, password FROM users WHERE userid = '%n' AND domain = '%d'

# userdb query to retrieve the user information. It can return fields:
#   uid - System UID (overrides mail_uid setting)
#   gid - System GID (overrides mail_gid setting)
#   home - Home directory
#   mail - Mail location (overrides mail_location setting)
#
# None of these are strictly required. If you use a single UID and GID, and
# home or mail directory fits to a template string, you could use userdb static
# instead. For a list of all fields that can be returned, see
# http://wiki2.dovecot.org/UserDatabase/ExtraFields
#
# Examples:
#   user_query = SELECT home, uid, gid FROM users WHERE userid = '%u'
#   user_query = SELECT dir AS home, user AS uid, group AS gid FROM users where userid = '%u'
#   user_query = SELECT home, 501 AS uid, 501 AS gid FROM users WHERE userid = '%u'
#
#user_query = \
#  SELECT home, uid, gid \
#  FROM users WHERE username = '%n' AND domain = '%d'
user_query = SELECT home, uid, gid FROM users WHERE userid = '%n' AND domain = '%d'

# If you wish to avoid two SQL lookups (passdb + userdb), you can use
# userdb prefetch instead of userdb sql in dovecot.conf. In that case you'll
# also have to return userdb fields in password_query prefixed with "userdb_"
# string. For example:
#password_query = \
#  SELECT userid AS user, password, \
#    home AS userdb_home, uid AS userdb_uid, gid AS userdb_gid \
#  FROM users WHERE userid = '%u'

# Query to get a list of all usernames.
#iterate_query = SELECT username AS user FROM users
# For using doveadm -A:
iterate_query = SELECT userid AS username, domain FROM users

EOF
chown root.dovecot /etc/dovecot/local-mysql.conf.ext
chmod u=rw,g=r,o= /etc/dovecot/local-mysql.conf.ext

systemctl restart dovecot.service
systemctl status dovecot.service

################################################################################
