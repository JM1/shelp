#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Restore GitLab from backup
#
# NOTE: Base installation must have been completed.
# NOTE: You can only restore a backup to exactly the same version of GitLab that you created it on!
#       See file backup_information.yml in your backup files (*_gitlab_backup.tar) for exact version that is required.

gitlab-ctl reconfigure

gitlab-ctl stop

# Now copy your backups to your servers GitLab backup path, e.g. /var/opt/gitlab/backups/

chmod o-rwx,g-rwx /var/opt/gitlab/backups/*
chown git.git /var/opt/gitlab/backups/*
chown root.root /var/opt/gitlab/backups/etc*

cd /tmp/
tar -xf /var/opt/gitlab/backups/etc-gitlab-*.tgz

mv -i /etc/gitlab/ /etc/gitlab.old
mv -i /tmp/etc/gitlab/ /etc/

gitlab-ctl start # GitLab must be running for restore
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq

gitlab-rake gitlab:backup:restore BACKUP=1464660000 # Replace 1464660000 with timestamp from /var/opt/gitlab/backups/[TIMESTAMP]_gitlab_backup.tar

gitlab-ctl start
gitlab-rake gitlab:check SANITIZE=true

rm -r /etc/gitlab.old

# (Optional) Adapt to changes like of hostname
vi /etc/gitlab/gitlab.rb 
# (Optional) Create a new certificate if hostname changed
cd /etc/gitlab/ssl/ && ...



gitlab-ctl reconfigure # Apply changes
gitlab-ctl restart

apt-get upgrade gitlab-ce

iptables -F INPUT

exit # the end
