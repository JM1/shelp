#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Setup a system with Debian 8 (Jessie), Debian 9 (Stretch), Debian 10 (Buster) or Debian 11 (Bullseye)
#

# Variables:
_DEV_=eth0                # devicename of primary network interface
_IP4_=10.10.10.10         # ipv4 address of primary network interface
_GW_=10.10.1.1            # ipv4 address of gateway
_DNS_=1.1.1.1             # ipv4 address of primary dns server
_HOSTNAME_=saloon         # hostname
_DOMAIN_=wildwildwest.com # domainname
_SSH_INSTALL_PWD_=...     # password you choose for Debian Installer remote installation
_HOSTNAMES_='Saloon saloon Saloon.WildWildWest.com salloon.wildwildwest.com'
#                         # lowercase/reg. case and with/without fqdn variants of _HOSTNAME_
_USER_=johnwayne          # username of primary user
_EMAIL_RECIPIENT_='john.wayne@wildwildwest.com' 
#                         # email of primary user

################################################################################
#                                                                              #
# Initial system setup using Debian Installer                                  #
#                                                                              #

# TL;DR
# - Boot Debian Expert Install
# - Setup network manually: _IP4_
# - Allow logins for root user
# - Setup hostname: _HOSTNAME_
# - Add additional user _USER_
# - At task selection chooose only "SSH server" and "Standard system utilities"
# - Select kernel 'linux-image-amd64'
# - Drivers to include in the initrd: "generic: include all available drivers"


# Step by Step Guide
#
# NOTE: Translations of Debian Installer can be found at:
#         https://d-i.debian.org/l10n-stats/
#         https://salsa.debian.org/installer-team/d-i/blob/master/packages/po/
#       e.g. for german language:
#         https://salsa.debian.org/installer-team/d-i/blob/master/packages/po/sublevel1/de.po
#         https://salsa.debian.org/installer-team/d-i/blob/master/packages/po/sublevel2/de.po
#         https://salsa.debian.org/installer-team/d-i/blob/master/packages/po/sublevel3/de.po
#         https://salsa.debian.org/installer-team/d-i/blob/master/packages/po/sublevel4/de.po
#         https://salsa.debian.org/installer-team/d-i/blob/master/packages/po/sublevel5/de.po
#
# Download netinst images for the "stable" release from e.g. https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/
# Boot Debian Installer via UEFI (if available) or BIOS (as fallback)
# Under 'Advanced' choose 'Expert Install' and..
#
# ..on Debian 9 (Stretch) or earlier do
#   edit grub command line and
#   add "net.ifnames=1" after "vmlinux..." statement,
#   click boot and ..
#
# ..on install prompt click on:
# - "Choose language":
#       "German"
#       => "Deutschland"
#       => "Deutschland - de_DE.UTF-8"
#       => Do not select extra locales, just continue
# - "Tastatur konfigurieren": "Deutsch"
# - "CD-ROM erkennen und einbinden" @ Debian 8 (Jessie):
#       "Fehlende Firmware von Wechseldatenträger laden?" <Nein>
# - "CD-ROM erkennen und einbinden" @ Debian 10 (Buster):
#       "Diese Module laden: [*] usb-storage (USB storage)" <Weiter>
#       => "CD-ROM gefunden" <Weiter>
# - "Installer-Komponenten von CD laden":
#       Select:
#       "[*] choose-mirror: Choose mirror to install from (menu-item)"
#       "[*] network-console: Continue installation remotely using SSH"
# - "Netzwerk-Hardware erkennen"
# - "Netzwerk einrichten": 
#       Select "Primäre Netzwerk-Schnittstelle" _DEV_
#       => "Netzwerk automatisch einrichten?" <Nein>
#       => "IP-Adresse:" _IP4_
#       => "Netzmaske:" _NM_
#       => "Gateway:" _GW_
#       => "Adresse des DNS-Servers:" _DNS_
#       => "Sind diese Informationen richtig?" <Ja>
#       => "Wartezeit (in Sekunden) für Erkennung einer Verbindung: 3" <Weiter>
#       => "Rechnername:" _HOSTNAME_
#       => "Domain-Name:" _DOMAIN_
# - "Installation über Fernzugriff (SSH) fortsetzen":
#       "Passwort für die Ferninstallation:" _SSH_INSTALL_PWD_
# 
# On your local system, open a ssh connection to installer on remote system:
ssh -o "UserKnownHostsFile /dev/null" installer@$_HOSTNAME_.$_DOMAIN_
# Once you see the network console for the Debian Installer, click on:
# - "Installer starten (Expertenmodus)"
# - "Spiegelserver für das Debian-Archiv wählen":
#       "Protokoll für Datei-Downloads:" "https" (or "http" if "https" is not available)
#       => "Daten von Hand eingeben"
#       => "Rechnername des Debian-Archiv-Spiegelservers:" debian.inf.h-brs.de
#       => "Debian-Archiv Spiegel-Verzeichnis:" /debian/
#       => "HTTP-Proxy-Daten (leer lassen für keinen Proxy):" leave blank and contine
# - "Benutzer und Passwörter einrichten"
#       "Shadow-Passwörter benutzen?" <Ja>
#       => "root das Anmelden erlauben?" <Ja>
#       => "Root-Passwort:"
#       => "Soll jetzt ein normales Benutzerkonto erstellt werden?" <Ja>
#       => "Vollständiger Name des neuen Benutzers:" ""
#       => "Benutzername für Ihr Konto:" _USER_
#       => "Wählen Sie ein Passwort für den neuen Benutzer:"
# - "Uhr einstellen"
#       "Die Uhr mittels NTP einstellen?" <Ja>
#       => "Zu verwendender NTP-Server:" confirm predefined nameserver
#       => "Wählen Sie Ihre Zeitzone:" "Europe/Berlin"
# - "Festplatten erkennen"
# - "Festplatten partitionieren":
#       "UEFI-Installation erzwingen?" <Ja>
#       => "Partitionierungsmethode:" "Manuell"
#       => ...
# - "Basissystem installieren"
#       "Zu installierender Kernel:" "linux-image-amd64"
#       => "In die initrd aufzunehmende Treiber:": "generisch: alle verfügbaren Treiber einbinden"
# - "Paketmanager konfigurieren"
#       "Eine andere CD oder DVD einlesen?" <Nein>
#       => "Einen Netzwerkspiegel verwenden?" <Ja>
#       => "Protokoll für Datei-Downloads:" "https" (or "http" if "https" is not available)
#       => "Daten von Hand eingeben"
#       => "Rechnername des Debian-Archiv-Spiegelservers:" debian.inf.h-brs.de
#       => "Debian-Archiv Spiegel-Verzeichnis:" /debian/
#       => "HTTP-Proxy-Daten (leer lassen für keinen Proxy):" leave blank and contine
#       => "»Non-free«-Software verwenden?" <Ja>
#       => "Paketdepots für Quellpakete in APT aktivieren?" <Nein>
#       => "Zu verwendende Dienste:" Select:
#             "[*] Sicherheitsaktualisierungen (von security.debian.org)"
#             "[*] Release-Updates"
#             "[ ] Rückportierte Software"
# - "Software auswählen und installieren"
#       "Update-Management für dieses System:" "Keine automatischen Updates"
#       => "An der Paketverwendungserfassung teilnehmen?" <Nein>
#       => "Welche Software soll installiert werden?" @ Debian 8 (Jessie):
#             "[*] SSH server"
#             "[*] Standard-Systemwerkzeuge"
#       => "Welche Software soll installiert werden?" @ Debian 10 (Buster):
#             "[*] Standard-Systemwerkzeuge"
# - "GRUB-Bootloader auf einer Festplatte installieren"
#       "GRUB-Installation in den EFI-Wechseldatenträgerpfad erzwingen?" <Nein>
# - "Installationsprotokolle speichern"
#       "Wie sollen die Installationsprotokolle übertragen oder gespeichert werden?"
#       => e.g. "Eingebundenes Dateisystem"
#       => e.g. "Verzeichnis, in dem die Installationsprotokolle gespeichert werden:" "/target/root/"
# - "Installation abschließen"
#       "Ist die Systemzeit auf UTC gesetzt?" <Ja>
#       => "Installation abgeschlossen" <Weiter>

#                                                                              #
################################################################################
#                                                                              #
# Initial system setup using using debootstrap                                 #
#                                                                              #

# TODO

#                                                                              #
################################################################################

################################################################################
#                                                                              #
# Management system configuration                                              #
#                                                                              #

# NOTE: Run all commands below at your management system. If you do not use an
#       management system, i.e. because you use a tty of your newly installed
#       system, then just skip this part.

sudo -s
vi /etc/hosts
# Add:
#  _IP4_ _HOSTNAMES_
exit

# Optional: Create *.desktop entry for SSH connection to _HOSTNAME_ and synchronize it with e.g. Unison:

ssh-copy-id _USER_@_HOSTNAME_

# Add entry to ~/.ssh/config

scp -rp ~/.bashrc ~/.screenrc ~/.vimrc _USER_@_HOSTNAME_:/home/_USER_/

scp -rp /root/.bashrc-root root@_HOSTNAME_:/root/

ssh _USER_@_HOSTNAME_
vi .ssh/authorized_keys # Add your ssh public keys

#                                                                              #
################################################################################

# System configuration
su

cp -raiv .bashrc .vimrc .screenrc /root/
cd /root/
chown root.root .bashrc .vimrc .screenrc
cp -raiv .bashrc-root /home/_USER_/.bashrc-_USER_
chown _USER_._USER_ /home/_USER_/.bashrc-_USER_

# Follow apt_repository.sh to configure APT repositories for your Debian release

rm /etc/apt/sources.list /etc/apt/sources.list~

apt-get update
apt-get dist-upgrade
apt-get clean

# NOTE: Sync' these package lists with vars/Debian-Buster.yml from Ansible role jm1.base_system!

apt-mark manual linux-image-amd64

apt-get install \
 acl \
 apt-listchanges \
 apt-transport-https \
 aptitude \
 at \
 locales \
 patch \
 p7zip-full \
 sudo \
 xz-utils

# Optional: TTYs
apt-get install \
 bash-completion \
 console-setup \
 curl \
 fzf \
 keyboard-configuration \
 kmod \
 libcap2-bin \
 man-db \
 screen \
 ssh \
 time \
 vim

# fzf requires Debian 10 (Buster) and later

# Optional: analysis tools
apt install atop htop iotop psmisc
apt install dlocate lshw lsof
apt install dnsutils ethtool iperf iproute2 iputils-ping net-tools

# Optional: partitioning and filesystem tools
apt-get install btrfs-progs dosfstools usbutils gdisk bsdtar rsync debconf-utils

# Optional: device mapper tools
apt-get install mdadm lvm2 cryptsetup

# Optional: hardware tools
apt-get install smartmontools lm-sensors hdparm bonnie++ fio s-tui nvme-cli

# Optional: IPMI tools
apt-get install freeipmi
apt-get install ipmitool openipmi-
systemctl stop ipmievd.service
systemctl disable ipmievd.service

# Optional: Follow nftables.sh to setup a firewall with nftables

# Optional: sshguard to protect from brute force attacks against ssh
apt-get install sshguard # automatically adds iptables filter chain

# Optional, e.g. for raspberry pi
apt-get install ifplugd fake-hwclock dbus dphys-swapfile

# Optional
apt-get install debootstrap strace tree

# Optional
apt-get install locales-all resolvconf

# Purge NFS
apt-get purge nfs-common rpcbind

# Optional: package cleanup
for section in interpreters libs localization metapackages misc perl shells text utils x11; do aptitude --schedule-only markauto ~i$section; done

aptitude # Set packages such as libraries to automatically installed

/usr/sbin/adduser _USER_ sudo

# Follow ssh_no_password_auth.sh

# logout and login again to reload environment variables, e.g. PATH

dpkg-reconfigure locales # Set de_DE.UTF-8 as default locale.
# or noninteractive'ly
sed -i -e 's/^LANG=.*/LANG=de_DE.UTF-8/g' /etc/default/locale
# Synchronize debconf database with locales' config which will help during
# package updates because debconf will not complain about config changes
dpkg-reconfigure -f noninteractive locales

# Optional, for more control during package installation and upgrades
LANG=C dpkg-reconfigure debconf # Choose "Dialog" and "Low"
# or noninteractive'ly
sed -z -i -e 's/\(: debconf\/priority\nValue: \)[^\n]*/\1low/' /var/cache/debconf/config.dat
dpkg-reconfigure -f noninteractive debconf

vi /etc/default/grub
# Change
#  GRUB_CMDLINE_LINUX_DEFAULT="quiet"
# to
#  GRUB_CMDLINE_LINUX_DEFAULT="quiet systemd.show_status=1"
update-grub

# Because Debian Installer assigns partition numbers in order of creation
# during install, you might want to sort partition numbers.
sgdisk --sort /dev/disk/by-id/ata-DEVICE

# (Optional) Add mount options relatime or noatime
vi /etc/fstab

################################################################################
#                                                                              #
# Network configuration, e.g. if not done by Debian Installer                  #
#                                                                              #

# Example: Home network
vi /etc/network/interfaces
# On Debian 8 (Jessie) change
#  iface eth0 inet dhcp
# to
#  iface eth0 inet static
#      address _IP4_
#      netmask 255.255.0.0
#      gateway 10.10.1.1
#      dns-nameservers 1.1.1.1
#      mtu 9000
#
# On Debian 10 (Buster) change
#  iface eth0 inet dhcp
# to
#  iface eth0 inet static
#      address _IP4_/16
#      gateway 10.10.1.1
#      dns-nameservers 1.1.1.1
#      mtu 9000

# Example: Lab network of Alexander Asteroth at Hochschule Bonn-Rhein-Sieg
vi /etc/network/interfaces
# On Debian 8 (Jessie) change
#  iface eth0 inet dhcp
# to
#  iface eth0 inet static
#      address _IP4_
#      netmask 255.255.255.0
#      gateway 10.20.130.1
#      dns-nameservers 194.95.66.9
#      dns-search inf.h-brs.de
#
# On Debian 10 (Buster) change
#  iface eth0 inet dhcp
# to
#  iface eth0 inet static
#      address _IP4_/16
#      gateway 10.20.130.1
#      dns-nameservers 194.95.66.9
#      dns-search inf.h-brs.de

# Follow hostname.sh to change the hostname.

reboot # to apply changes

#                                                                              #
################################################################################

# AppArmor configuration
# Optional: Follow apparmor_setup.sh to set up AppArmor

# Mail configuration
# Optional: Follow exim.sh to configure Exim for mail support

# Unattended upgrades configuration
# Optional: Follow apt_unattended_upgrades.sh to enable unattended upgrades

# Time synchronization configuration
# Optional: Follow chrony.sh to configure time synchronization with chrony

# Filesystem Maintenance
# Optional: Follow filesystem_maintenance.md

# Filesystem snapshots
# Optional: Follow snapper.sh to periodically do filesystem snapshots

# Virtualisation configuration
# Optional: Follow libvirt_setup.sh to install libvirt for virtualization

################################################################################
#                                                                              #
# Monitoring configuration                                                     #
#                                                                              #

# Low disk space alert
cat << 'EOF2' > /etc/cron.daily/low_disk_space_alert
#!/bin/sh
# 2016 Jakob Meng, <jakobmeng@web.de>
# Send alert mails when disk space is running low

THRESHOLD=90 # in percent
RECIPIENT=root
MOUNTS= # e.g. empty to check all mountpoints or list of mounts '/ /opt/ /home/'

if [ -f /etc/default/low_disk_space_alert ]; then
    . /etc/default/low_disk_space_alert
fi


if [ "${MOUNTS}" = '' ]; then
    DF="$(df | tail -n+2)"
else
    DF=
    for mount in ${MOUNTS}; do
        DF="$DF$(df "${mount}" | tail -n+2)\n"
    done
fi

MSG=
#/bin/echo -e "${DF}" |
while read line; do
    MOUNT="$(echo ${line} | awk '{ print $6 }')"
    USAGE="$(echo ${line} | awk '{ print $5 }' | cut -d'%' -f1)"
    if [ "${USAGE}" -gt "${THRESHOLD}" ]; then
        MSG="${MSG} ${MOUNT}: ${USAGE}%\n"
    fi
done << EOF
${DF}
EOF

if [ "${MSG}" != '' ]; then
    /bin/echo -e "System $(hostname) is running out of disk space:\n${MSG}" | \
      mail -s "$(hostname): Low disk space alert" "${RECIPIENT}"
fi
EOF2

chmod a+x /etc/cron.daily/low_disk_space_alert

apt install lm-sensors
# Use sensors-detect to add required modules automatically to /etc/modules
sensors-detect

# Optional: Follow smart_monitor.sh
# Optional: Follow btrfs_stats.sh
# Optional: Follow lvm_stats.sh
# Optional: Follow fancontrol.sh
# Optional: Follow storcli_alert.sh

# TODO: Implement ECC memory monitoring
# Ref.: https://serverfault.com/questions/643542/how-do-i-get-notified-of-ecc-errors-in-linux/888461#888461

# Optional: Monitor hdd temperature with hddtemp
#
# On Debian 11 (Bullseye) and earlier
#
# NOTE:
#
# hddtemp (0.3-beta15-54) unstable; urgency=medium
#
#   hddtemp has been dead upstream for many years and is therefore in a minimal
#   maintenance mode. It will be shipped in the Debian Bullseye release, but
#   will not be present in the Debian Bookworm release.
#
#   Nowadays the 'drivetemp' kernel module is a better alternative. It uses the
#   Linux Hardware Monitoring kernel API (hwmon), so the temperature is returned
#   the same way and using the same tools as other sensors.
#
#   Loading this module is as easy as creating a file in the /etc/modules-load.d
#   directory:
#
#     echo drivetemp > /etc/modules-load.d/drivetemp.conf
#
#  -- Aurelien Jarno <aurel32@debian.org>  Tue, 02 Feb 2021 20:27:44 +0100
#
# Ref.: /usr/share/doc/hddtemp/NEWS.Debian.gz
apt-get install hddtemp

#                                                                              #
################################################################################

# System Audit & Review
# Follow debian_audit.sh
# Follow debian_backup.sh

exit # the end
