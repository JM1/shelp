#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Monitor BTRFS filesystems periodically for errors
#

cat << 'EOF' > /etc/cron.daily/btrfs_stats
#!/bin/sh
# 2019-2021 Jakob Meng, <jakobmeng@web.de>
# Monitor BTRFS filesystems for errors
# Ref.: https://superuser.com/a/999542/629550


lsblk -P -o PATH,FSTYPE -n | while read VARS; do
    DEVICE="$(eval $VARS && echo $PATH)"
    FSTYPE="$(eval $VARS && echo $FSTYPE)"
    if [ "$FSTYPE" = "btrfs" ]; then
        btrfs device stats "$DEVICE" | awk 'NF' | { grep -vE ' 0$' || true; }
    fi
done

EOF

chmod a+x /etc/cron.daily/btrfs_stats
