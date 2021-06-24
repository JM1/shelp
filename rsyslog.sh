#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# rsyslog
#

# log everything to /dev/tty12 and /var/log/all
cat << 'EOF' > /etc/rsyslog.d/all.conf 
# 2009-2018 Jakob Meng, <jakobmeng@web.de>
# Log everything

*.*                             /dev/tty12
*.*                             /var/log/all

EOF

# Rotate /var/log/all every third day
cat << 'EOF' > /etc/logrotate.d/all
# 2009-2018 Jakob Meng, <jakobmeng@web.de>
# Rotiert die Datei /var/log/all jeden dritten Tag. Die Datei wurde in /etc/rsyslog.d/all.conf definiert!
/var/log/all
{
        #rotate 3
        #weekly
        rotate 30
        daily
        missingok
        notifempty
        compress
        delaycompress
        sharedscripts
        postrotate
                invoke-rc.d rsyslog rotate > /dev/null
        endscript
}

EOF
