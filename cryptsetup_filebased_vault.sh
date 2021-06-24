#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Erstellen einer verschlüsselten Partition als Datei im Dateisystem
#
# References:
# [1] http://forums.gentoo.org/viewtopic-t-274651.html
# [2] http://forums.gentoo.org/viewtopic-p-4273793.html#4273793

##########
# Vorbereitungen treffen

#Zuerst müssen die entsprechenden Pakete installiert werden.
apt-get install libpam-mount cryptsetup

#Ein paar Variablen für die folgenden Schritte
FILE_KEY="/home/johnwayne/.vault.key"
FILE_KEY_OLD="$FILE_KEY.old"
FILE_IMG="/home/johnwayne/.vauld.img"
LOOP_DEV="/dev/loop5"
MAPPER_DEV="vault"

##########
# Erstellung der LUKS Partition

KEY=`tr -cd [:graph:] < /dev/urandom | head -c 79`

#Der Key wird nun verschlüsselt abgespeichert. Bei der Frage nach dem Verschlüsselungspasswort bitte das Loginpasswort eingeben!
echo $KEY | openssl aes-256-cbc -md sha512 > "$FILE_KEY"

#Leere key.old Datei erstellen, damit das Passwortänderungsscript passwdehd später funktioniert
touch "$FILE_KEY_OLD"

#Erzeugt eine neue Datei (1024MB groß), welche später als Partition verwendet wird
dd if=/dev/zero of="$FILE_IMG" bs=1M count=1024
losetup "$LOOP_DEV" "$FILE_IMG"

#LUKS Partition erstellen
openssl aes-256-cbc -md sha512 -d -in "$FILE_KEY" | cryptsetup -v -c aes-cbc-essiv:sha256 -s 256 -h sha512 luksFormat "$LOOP_DEV"

#LUKS Partition öffnen
openssl aes-256-cbc -md sha512 -d -in "$FILE_KEY" | cryptsetup luksOpen "$LOOP_DEV" "$MAPPER_DEV"

##########
# Anpassen der verschlüsselten Partition

# Dateisystem auf /dev/mapper/$MAPPER_DEV erstellen, mounten und Dateien drauf kopieren
# Beispiel:
# 	mkfs.ext3 /dev/mapper/$MAPPER_DEV
#	mount /dev/mapper/$MAPPER_DEV /mnt/tmp1/
#	rsync -vaHAX --delete /home/johnwayne/vault/ /mnt/tmp1/
#	umount /mnt/tmp1
#	umount /home/johnwayne/vault #Unmounten, damit keiner mehr Veränderungen vornehmen kann (würden nicht in der neuen Partition gespeichert!)

#Aufräumarbeiten
cryptsetup luksClose "$MAPPER_DEV"
losetup -d "$LOOP_DEV"

#Dateiberechtigungen anpassen
chown root.root   "$FILE_KEY" "$FILE_KEY_OLD" "$FILE_IMG"
chmod g-rwx,o-rwx "$FILE_KEY" "$FILE_KEY_OLD" "$FILE_IMG"

##########
# PAM_MOUNT anpassen

# Um das automatische Einbinden der verschlüsselten Partition bei jedem Login zu erlauben, muss folgendes in den <pam_mount></pam_mount> Tag der Datei /etc/security/pam_mount.conf.xml eingefügt werden:
# Beispiel (muss angepasst werden!):
# <volume fskeycipher="aes-256-cbc" fskeyhash="sha512" options="fsck,noexec,nodev,nosuid,relatime,cipher=aes-cbc-essiv:sha256,keybits=256,hash=sha512" fskeypath="/home/johnwayne/.vault.key" user="johnwayne" mountpoint="/home/johnwayne/vault" path="/home/johnwayne/.vault.img" fstype="crypt" />

# Zum Schluss muss eventuell(!!!) noch ein @include common-pammount in die Dateien /etc/pam.d/kdm und /etc/pam.d/login etc. eingefügt werden.

##########
