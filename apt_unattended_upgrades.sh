#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Unattended upgrades for APT
#

# Preseed debconf database
# NOTE: The debconf selection will be ignored if package is already installed.
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | debconf-set-selections

apt-get install unattended-upgrades

dpkg-reconfigure -plow unattended-upgrades
# Answers for debconf questions:
#  [EN] Automatically download and install stable updates? <Yes>
#  [DE] Aktualisierungen für Stable automatisch herunterladen und installieren? <Ja>
# Ref.: /var/lib/dpkg/info/unattended-upgrades.templates
#
# or non-interactively
# Ref.: /var/lib/dpkg/info/unattended-upgrades.postinst
cp -rav /usr/share/unattended-upgrades/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
# Synchronize debconf database with locales' config which will help during
# package updates because debconf will not complain about config changes
dpkg-reconfigure -f noninteractive unattended-upgrades

# Enable service which delays shutdown or reboots during upgrades
systemctl is-enabled unattended-upgrades.service || systemctl enable unattended-upgrades.service

dash # bash interprets tabs which causes problems with patch

# NOTE: Debian 10 (Buster) has changed this to allow updates with label=Debian,
#       which allows applying stable updates in stable releases and
#       following all package updates in testing and unstable.
#       Ref.: /usr/share/doc/unattended-upgrades/NEWS.Debian.gz

# Optional: Do unattended-upgrades for all available updates.
# On Debian 9 (Stretch) and earlier:
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig	2016-05-09 11:07:32.020000000 +0200
+++ /etc/apt/apt.conf.d/50unattended-upgrades	2016-05-09 11:15:36.424000000 +0200
@@ -37,6 +37,7 @@
 //      "o=Debian,a=stable-updates";
 //      "o=Debian,a=proposed-updates";
         "origin=Debian,codename=${distro_codename},label=Debian-Security";
+        "origin=*";
 };
 
 // List of packages to not update (regexp are supported)
EOF
# On Debian 10 (Buster)
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig	2019-06-08 16:59:45.000000000 +0200
+++ /etc/apt/apt.conf.d/50unattended-upgrades	2020-02-16 14:27:15.481253056 +0100
@@ -30,6 +30,7 @@
 //      "origin=Debian,codename=${distro_codename}-proposed-updates";
         "origin=Debian,codename=${distro_codename},label=Debian";
         "origin=Debian,codename=${distro_codename},label=Debian-Security";
+        "origin=*";
 
         // Archive or Suite based matching:
         // Note that this will silently match a different release after

EOF
# On Debian 11 (Bullseye)
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig      2021-02-19 13:11:42.000000000 +0100
+++ /etc/apt/apt.conf.d/50unattended-upgrades   2021-05-24 11:47:57.742097117 +0200
@@ -31,6 +31,7 @@
         "origin=Debian,codename=${distro_codename},label=Debian";
         "origin=Debian,codename=${distro_codename},label=Debian-Security";
         "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
+        "origin=*";
 
         // Archive or Suite based matching:
         // Note that this will silently match a different release after
EOF


# Send emails on unattended-upgrades
# On Debian 9 (Stretch) and earlier
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig	2015-06-29 08:42:49.000000000 +0200
+++ /etc/apt/apt.conf.d/50unattended-upgrades	2016-03-08 18:50:49.280000000 +0100
@@ -68,7 +69,7 @@
 // If empty or unset then no email is sent, make sure that you
 // have a working mail setup on your system. A package that provides
 // 'mailx' must be installed. E.g. "user@example.com"
-//Unattended-Upgrade::Mail "root";
+Unattended-Upgrade::Mail "root";
 
 // Set this value to "true" to get emails only on errors. Default
 // is to always send a mail if Unattended-Upgrade::Mail is set
EOF
# On Debian 10 (Buster)
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig	2020-02-16 14:31:32.317137137 +0100
+++ /etc/apt/apt.conf.d/50unattended-upgrades	2020-02-16 14:32:40.445076902 +0100
@@ -91,6 +91,7 @@
 // have a working mail setup on your system. A package that provides
 // 'mailx' must be installed. E.g. "user@example.com"
 //Unattended-Upgrade::Mail "";
+Unattended-Upgrade::Mail "root";
 
 // Set this value to "true" to get emails only on errors. Default
 // is to always send a mail if Unattended-Upgrade::Mail is set

EOF
# On Debian 11 (Bullseye)
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig      2021-02-19 13:11:42.000000000 +0100
+++ /etc/apt/apt.conf.d/50unattended-upgrades   2021-05-24 11:49:59.160527221 +0200
@@ -92,6 +92,7 @@
 // have a working mail setup on your system. A package that provides
 // 'mailx' must be installed. E.g. "user@example.com"
 //Unattended-Upgrade::Mail "";
+Unattended-Upgrade::Mail "root";
 
 // Set this value to one of:
 //    "always", "only-on-error" or "on-change"
EOF
# or
sed -i -e 's/\/\/Unattended-Upgrade::Mail "";/\/\/Unattended-Upgrade::Mail "";\n'\
'Unattended-Upgrade::Mail "root";/g' /etc/apt/apt.conf.d/50unattended-upgrades

# Restart after unattended-upgrades
# NOTE: Do not use this on systems with encrypted root filesystems or
#       your system will stop (and ask for passphrase) during reboot!
# On Debian 9 (Stretch) and earlier
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig	2015-06-29 08:42:49.000000000 +0200
+++ /etc/apt/apt.conf.d/50unattended-upgrades	2016-03-08 18:50:49.280000000 +0100
@@ -80,7 +81,7 @@
 
 // Automatically reboot *WITHOUT CONFIRMATION* if
 //  the file /var/run/reboot-required is found after the upgrade 
-//Unattended-Upgrade::Automatic-Reboot "false";
+Unattended-Upgrade::Automatic-Reboot "true";
 
 // If automatic reboot is enabled and needed, reboot at the specific
 // time instead of immediately
EOF
# On Debian 10 (Buster)
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig	2020-02-16 14:32:40.445076902 +0100
+++ /etc/apt/apt.conf.d/50unattended-upgrades	2020-02-16 14:39:54.995592638 +0100
@@ -111,6 +111,7 @@
 // Automatically reboot *WITHOUT CONFIRMATION* if
 //  the file /var/run/reboot-required is found after the upgrade
 //Unattended-Upgrade::Automatic-Reboot "false";
+Unattended-Upgrade::Automatic-Reboot "true";
 
 // Automatically reboot even if there are users currently logged in
 // when Unattended-Upgrade::Automatic-Reboot is set to true

EOF
# On Debian 11 (Bullseye)
cat << 'EOF' | patch -p0 -d /
--- /etc/apt/apt.conf.d/50unattended-upgrades.orig      2021-02-19 13:11:42.000000000 +0100
+++ /etc/apt/apt.conf.d/50unattended-upgrades   2021-05-24 11:50:40.699994374 +0200
@@ -113,6 +114,7 @@
 // Automatically reboot *WITHOUT CONFIRMATION* if
 //  the file /var/run/reboot-required is found after the upgrade
 //Unattended-Upgrade::Automatic-Reboot "false";
+Unattended-Upgrade::Automatic-Reboot "true";
 
 // Automatically reboot even if there are users currently logged in
 // when Unattended-Upgrade::Automatic-Reboot is set to true
EOF
# or
sed -i -e 's/\/\/Unattended-Upgrade::Automatic-Reboot "false";/\/\/Unattended-Upgrade::Automatic-Reboot "false";\n'\
'Unattended-Upgrade::Automatic-Reboot "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades

# Follow apt_cache_cleanup.sh to cleanup package cache intervals periodically

systemctl restart unattended-upgrades.service
# or
service unattended-upgrades restart

# List pending, old and obsolete configuration files
cat << 'EOF' > /etc/cron.daily/detect_config_changes
#!/bin/sh
# 2021 Jakob Meng, <jakobmeng@web.de>
# List pending, old and obsolete configuration files

find /etc -iname '*.ucftmp*' -o -iname '*.dpkg-*' -o -iname '*.ucf-*' -o -name '*.merge-error' | sort | uniq

EOF

chmod a+x /etc/cron.daily/detect_config_changes

exit
