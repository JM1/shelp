#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Scrubbing of LVM RAID LVs
#

cat << 'EOF' > /etc/cron.monthly/lvm_scrub
#!/bin/sh
# 2021 Jakob Meng, <jakobmeng@web.de>
# Scrub all LVM RAID LVs
# Ref.: man lvmraid

lvs -o lv_full_name,lv_health_status,raid_sync_action --reportformat json |
  jq -c '.report[0].lv[]' |
  while read LINE; do
    lv_full_name=$(echo "$LINE" | jq -c -r '.lv_full_name')
    lv_health_status=$(echo "$LINE" | jq -c -r '.lv_health_status')
    raid_sync_action=$(echo "$LINE" | jq -c -r '.raid_sync_action')

    if [ -z "$raid_sync_action" ]; then
        # LV is no RAID LV
        continue
    fi

    if [ "$raid_sync_action" != "idle" ] || [ -n "$lv_health_status" ]; then
        echo "Skipped $lv_full_name with raid_sync_action='$raid_sync_action' and lv_health_status='$lv_health_status'"
        continue
    fi

    lvchange --syncaction check "$lv_full_name"
done

EOF

chmod a+x /etc/cron.monthly/lvm_scrub
