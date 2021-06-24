#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# AppArmor
#

# Disable printk ratelimiting to prevent messages in dmesg like 
#  audit_printk_skb: ... callbacks suppressed
echo 0 > /proc/sys/kernel/printk_ratelimit

# printk ratelimit defaults to 5
cat /proc/sys/kernel/printk_ratelimit

# audit accesses
dmesg | grep -v 'name="/proc' | grep -v 'name="/sys' | grep audit | awk '{print $7" "$8" "$9 }' | sort | uniq
