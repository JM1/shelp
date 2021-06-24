#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# debconf - Debian package configuration system
# Ref.:
#  man debconf
#  man 7 debconf
#  man dpkg-reconfigure
#  man debconf-set-selections

# See the current configuration of a package
debconf-show debconf

# See the current configuration of all packages
apt-get install debconf-utils
debconf-get-selections

# debconf configuration
less /etc/debconf.conf

# enable verbose output
export DEBCONF_DEBUG=developer

# Reconfigure an already installed package
dpkg-reconfigure locales # Set de_DE.UTF-8 as default locale.

# Insert new values into the debconf database and then reconfigure an already installed package
#
# NOTE: "Only use this command to seed debconf values for packages that will be or are installed. Otherwise you can end
#        up with values in the database for uninstalled packages that will not go away, or with worse problems involving
#        shared values. It is recommended that this only be used to seed the database if the originating machine has an
#        identical install."
#       Ref.: LANG=C man debconf-set-selections
#
# NOTE: Existing configurations such as those of openssh-server and unattended-upgrades cannot be changed using
#       dpkg-reconfigure with noninteractive frontend. "It is by design of debconf that settings on the system take
#       precedence over any values set in the debconf database. There is a valid use case for being able to preseed the
#       set of modules that you want to install, but it is difficult to implement this while maintaining the requirement
#       to respect any local changes to the config files." [2]
#
#       For example, suppose that unattended-upgrades are disabled:
#
#       $> export DEBCONF_DEBUG=developer
#       $> echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | debconf-set-selections
#       $> dpkg-reconfigure -f noninteractive unattended-upgrades
#         debconf (developer): starting /var/lib/dpkg/info/unattended-upgrades.config reconfigure 2.8
#         debconf (developer): <-- SET unattended-upgrades/enable_auto_updates false
#         debconf (developer): --> 0 value set
#         debconf (developer): <-- INPUT low unattended-upgrades/enable_auto_updates
#         debconf (developer): --> 30 question skipped
#         debconf (developer): <-- GO
#         debconf (developer): --> 0 ok
#         debconf (developer): starting /var/lib/dpkg/info/unattended-upgrades.postinst configure 2.8
#         debconf (developer): <-- GET unattended-upgrades/enable_auto_updates
#         debconf (developer): --> 0 false
#         debconf (developer): <-- X_LOADTEMPLATEFILE /var/lib/dpkg/info/ucf.templates ucf
#         debconf (developer): --> 0
#         debconf (developer): <-- X_LOADTEMPLATEFILE /var/lib/dpkg/info/ucf.templates ucf
#         debconf (developer): --> 0
#
#      When using dpkg-reconfigure with noninteractive frontend, debconf will load answers to debconf questions from
#      /var/lib/dpkg/info/*.config files which are scripts that generate debconf answers based on the actual system
#      configuration. With an interactive frontend, debconf would now show questions to users and allow them to change
#      the debconf answers. With noninteractive frontend, debconf will skip these questions ("30 question skipped") and
#      use the answers from /var/lib/dpkg/info/*.config scripts based on the current configuration instead and then
#      update answers from the debconf database to these generated settings later (in /var/lib/dpkg/info/*.postinst
#      scripts, not shown above). Workarounds using DEBCONF_DB_OVERRIDE [3] do not work, so this won't help:
#
#      $> DEBCONF_DB_OVERRIDE='File {/var/cache/debconf/config.dat}' dpkg-reconfigure -f noninteractive unattended-upgrades
#
#      The only valid workaround with noninteractive frontend is to change config files directly and then call
#
#      $> dpkg-reconfigure -f noninteractive unattended-upgrades
#
#      to update the debconf database with the new values. Unfortunately how to change the configuration files depends
#      on the packages, details can be found in the /var/lib/dpkg/info/*.postinst scripts.
#
#      Ref.:
#      [1] https://serverfault.com/a/914012/373320
#      [2] https://bugs.launchpad.net/ubuntu/+source/pam/+bug/682662/comments/1
#      [3] https://github.com/zecrazytux/ansible-library-extra/issues/1#issuecomment-99636309
#
# NOTE: The following example preseeds a package and only works if package locales has NOT been installed yet!
cat << 'EOF' | debconf-set-selections
locales locales/locales_to_be_generated multiselect 'en_US.UTF-8 UTF-8', 'de_DE.UTF-8 UTF-8'
locales locales/default_environment_locale select 'de_DE.UTF-8'
EOF
apt-get install locales

# Changes to debconf questions with debconf-set-selections will be overwriten by dpkg-reconfigure but calling 
# dpkg-reconfigure with noninteractive frontend may still be useful! It will update the debconf database to the current
# settings and debconf will not complain about config changes when packages get updated later.
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
# or
dpkg-reconfigure -f noninteractive locales
