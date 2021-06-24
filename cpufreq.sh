#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Disable processor boosting
#
# Ref.: https://www.kernel.org/doc/Documentation/cpu-freq/boost.txt

cat 1 > /sys/devices/system/cpu/cpufreq/boost

# Intel-specific alternative 1
# Disable Intel Turbo Boost
# Ref.: http://askubuntu.com/a/620114
echo "Disabling Intel Turbo Boost..."
{ cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver 2>/dev/null || echo 'unknown'; } | \ 
   grep -v intel_pstate >/dev/null && {
        echo 'Intel Turbo Boost could NOT be disabled, do you use a intel cpu?'
} || {
        echo '1' > /sys/devices/system/cpu/intel_pstate/no_turbo
}

# Intel-specific alternative 2
# Disable Intel Turbo Boost (requires "msr" kernel module to be loaded)
# Ref.: http://luisjdominguezp.tumblr.com/post/19610447111/disabling-turbo-boost-in-linux
modprobe msr
echo -n "Disabling Intel Turbo Boost (requires 'msr' kernel module to be loaded)..."
for i in 0 1 2 3; do
       wrmsr -p$i 0x1a0 0x4000850089
done

########################################

# Read CPU frequency
cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq

########################################
