#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Monitor LVM LVs periodically for errors
#

cat << 'EOF' > /etc/cron.daily/lvm_stats
#!/bin/sh
# 2021 Jakob Meng, <jakobmeng@web.de>
# Monitor LVM for errors

lvs -o lv_full_name,integritymismatches,raid_mismatch_count,raid_sync_action,lv_health_status,copy_percent,sync_percent --reportformat json |
  jq -c '.report[0].lv[]' |
  while read LINE; do
    lv_full_name=$(echo "$LINE" | jq -c -r '.lv_full_name')
    integritymismatches=$(echo "$LINE" | jq -c -r '.integritymismatches')
    raid_mismatch_count=$(echo "$LINE" | jq -c -r '.raid_mismatch_count')
    raid_sync_action=$(echo "$LINE" | jq -c -r '.raid_sync_action')
    lv_health_status=$(echo "$LINE" | jq -c -r '.lv_health_status')
    # LVs with Cache Sub LVs have copy_percent and sync_percent as well so no check possible here but that
    # is ok because raid_sync_action will not be "idle" if copy_percent and sync_percent are not "100,00".
    copy_percent=$(echo "$LINE" | jq -c -r '.copy_percent')
    sync_percent=$(echo "$LINE" | jq -c -r '.sync_percent')

    if [ \( -n "$integritymismatches" \) -a \( "$integritymismatches" != "0" \) ] ||
       [ \( -n "$raid_mismatch_count" \) -a \( "$raid_mismatch_count" != "0" \) ] ||
       [ \( -n "$raid_sync_action"    \) -a \( "$raid_sync_action" != "idle" \) ] ||
       [ -n "$lv_health_status" ]; then
        echo "$LINE" | jq
    fi
done

vgs -o vg_name,vg_missing_pv_count --reportformat json |
  jq -c '.report[0].vg[]' |
  while read LINE; do
    vg_name=$(echo "$LINE" | jq -c -r '.vg_name')
    vg_missing_pv_count=$(echo "$LINE" | jq -c -r '.vg_missing_pv_count')
    if [ "$vg_missing_pv_count" != "0" ]; then
        echo "$LINE" | jq
    fi
done

EOF

chmod a+x /etc/cron.daily/lvm_stats
