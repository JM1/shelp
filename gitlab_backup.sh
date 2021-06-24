#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# GitLab Backup
#

apt-get install rsync

cat << 'EOF' >> /etc/cron.d/gitlab
# Create a backup of the GitLab system including omnibus-gitlab configuration
# References:
#  https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md
#  https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/backups.md

# m h dom mon dow user  command
30 3   * * 2-6   root   umask 0077; tar cfz "/var/opt/gitlab/backups/$(date "+etc-gitlab-\%s.tgz")" -C / etc/gitlab
59 3   * * 2-6   root   gitlab-rake gitlab:backup:create
EOF
