#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Synchronize /boot/efi and /boot/efi-mirror
#

# NOTE: /boot/efi-mirror must be mounted writeable!
cat << 'EOF' > /etc/apt/apt.conf.d/85wana-sync-boot-efi-mirror
// 2019-2020 Jakob Meng, <jakobmeng@web.de>

DPkg {
    Post-Invoke {
        "sync";
        "echo 'Rsyncing /boot/efi to /boot/efi-mirror'";
        "if ! mountpoint --quiet /boot/efi;        then echo '/boot/efi not mounted';        false; fi";
        "if ! mountpoint --quiet /boot/efi-mirror; then echo '/boot/efi-mirror not mounted'; false; fi";
        "/usr/bin/rsync --quiet --no-motd -vaHAX --delete /boot/efi/ /boot/efi-mirror/";
   };
};

EOF

# or
# NOTE: /boot/efi-mirror must be mounted writeable!
cat << 'EOF' > /etc/cron.monthly/sync_boot_efi
#!/bin/sh
# 2016 Jakob Meng, <jakobmeng@web.de>
# Synchronize /boot/efi/ and /boot/efi-mirror/

/usr/bin/rsync --quiet --no-motd -vaHAX --delete /boot/efi/ /boot/efi-mirror/

EOF

chmod a+x /etc/cron.monthly/sync_boot_efi
