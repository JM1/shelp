#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# StorCLI alert
#

# First get StorCLI (storcli.sh)

apt install jq

cat << 'EOF' >> /etc/cron.daily/storcli_alert
#!/bin/sh
# Send alert when StorCLI detects failed disks

set -e

storcli64 /call /eall /sall show J | \
    jq '.Controllers[]."Response Data"."Drive Information"[] | select(."State" != "Onln" and ."State" != "GHS" and ."State" != "UGood")'

EOF

chmod a+x /etc/cron.daily/storcli_alert
