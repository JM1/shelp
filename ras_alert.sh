#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Alerts for Reliablity, Availability and Serviceability (RAS) reports like ECC memory errors
#

apt install rasdaemon

# NOTE: On Debian 11 (Bullseye) you may have to apply the referenced patch to fix a bug in ras-mc-ctl.
#       Ref.: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=973053#20

cat << 'EOF' > /etc/cron.daily/ras_alert
#!/bin/sh
# 2021-2026 Jakob Meng, <jakobmeng@web.de>
# Alerts for Reliablity, Availability and Serviceability (RAS) reports, e.g.
# report both correctable and uncorrectable ECC memory errors.
#
# Ref.:
# https://serverfault.com/a/997646/373320
# https://www.setphaserstostun.org/posts/monitoring-ecc-memory-on-linux-with-rasdaemon/

set -e
#set -x

status="$(ras-mc-ctl --status)"
if [ "$status" != "ras-mc-ctl: drivers are loaded." ]; then
    echo "$status" >&2
    exit 255
fi

good_summary_v0_6_8="No Memory errors.
No PCIe AER errors.
No Extlog errors.
No MCE errors."

good_summary_v0_8_3="No Memory errors.
No PCIe AER errors.
No ARM processor errors.
No CXL AER uncorrectable errors.
No CXL AER correctable errors.
No CXL overflow errors.
No CXL poison errors.
No CXL generic errors.
No CXL general media errors.
No CXL DRAM errors.
No CXL memory module errors.
No Extlog errors.
No devlink errors.
No disk errors.
No Memory failure errors.
No MCE errors."

summary="$(ras-mc-ctl --summary | grep '[^[:blank:]]')"

if [ "$summary" != "$good_summary_v0_6_8" ] && [ "$summary" != "$good_summary_v0_8_3" ]; then
    echo "$summary" >&2
    exit 255
fi

EOF

chmod a+x /etc/cron.daily/ras_alert
