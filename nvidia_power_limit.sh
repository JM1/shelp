#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Enforce minimal power limit on NVIDIA graphic cards
#
# Ref.:
# https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Custom_TDP_Limit

apt-get install nvidia-driver nvidia-smi libxml2-utils

# NOTE: On Debian 12 (Bookworm) only
cat << 'EOF' > /etc/systemd/system/nvidia-power-limit.service
# 2021-2024 Jakob Meng, <jakobmeng@web.de>
#
# Enforce minimal power limit on NVIDIA graphic cards to decrease
# temperatures and power consumption but also performance.
# Ref.: https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Custom_TDP_Limit

[Unit]
Description=Enforce minimal power limit on NVIDIA graphic cards
Wants=syslog.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "nvidia-smi -pl \"$(nvidia-smi -q -x | xmllint --xpath '/nvidia_smi_log/gpu/gpu_power_readings/min_power_limit/text()' - | awk '{ print $1 }')\""

[Install]
WantedBy=multi-user.target
EOF

# NOTE: On Debian 11 (Bullseye) only
cat << 'EOF' > /etc/systemd/system/nvidia-power-limit.service
# 2021 Jakob Meng, <jakobmeng@web.de>
#
# Enforce minimal power limit on NVIDIA graphic cards to decrease
# temperatures and power consumption but also performance.
# Ref.: https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Custom_TDP_Limit

[Unit]
Description=Enforce minimal power limit on NVIDIA graphic cards
Wants=syslog.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "nvidia-smi -pl \"$(nvidia-smi -q -x | xmllint --xpath '/nvidia_smi_log/gpu/power_readings/min_power_limit/text()' - | awk '{ print $1 }')\""

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now nvidia-power-limit.service
systemctl status nvidia-power-limit.service

# NOTE: On Debian 10 (Buster) only
#
# With older NVIDIA drivers the graphic card could be forced to use the lowest performance level by specifying kernel
# parameters. These parameters do not seem to have any effect since version 460.* or 470.* of the NVIDIA driver.
cat << 'EOF' > /etc/modprobe.d/nvidia-power-limit.conf
# 2019-2020 Jakob Meng, <jakobmeng@web.de>
# References:
#  modinfo nvidia-current
#  https://devtalk.nvidia.com/default/topic/980313/linux/force-gtx1080-performance-level-to-reduce-power-consumption-under-linux/post/5032304/#5032304
#  https://forums.opensuse.org/showthread.php/410089-NVidia-Powermizer-how-to-tweak?p=1957302#post1957302
#  https://devtalk.nvidia.com/default/topic/1044230/linux/powermizer-quot-powersave-quot-configuration-not-working-any-more/post/5297893/#5297893
#  https://devtalk.nvidia.com/default/topic/982987/linux/power-mizer-difference-between-powermizerdefault-and-powermizerlevel/post/5237891/#5237891

# Force lowest performance level to minimize power consumption and noise
options nvidia NVreg_RegistryDwords="OverrideMaxPerf=0x1"
# or
#options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"

# Allow lowest and second lowest performance levels
#options nvidia NVreg_RegistryDwords="OverrideMaxPerf=0x2"

# Force second lowest performance level
#options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x2; PowerMizerDefault=0x2; PowerMizerDefaultAC=0x2"
EOF
