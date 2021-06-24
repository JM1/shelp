#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Disable/(Re-)Enable suspend and hibernation
#
# References:
#  https://wiki.debian.org/Suspend#Disable_suspend_and_hibernation
#  https://askubuntu.com/a/858621

# show all targets
systemctl list-unit-files --type=target --all

# Disable
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Enable
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
