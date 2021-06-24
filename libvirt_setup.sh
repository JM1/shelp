#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Virtualisation configuration
#

# Why libvirt?
# - supports multiple virtualization solutions, e.g. QEMU/KVM and Xen
# - allows non-root qemu:///session
# - already packaged in Debian (as opposed to Proxmox VE)
# - scriptable
# - readable XML based configuration
# - GUI support incl. VNC/Spice display and USB redirection
# - small, e.g. no webserver required (smaller attack surface)

# Debian 8 (Jessie) and Debian 9 (Stretch)
apt-get install libvirt-clients libvirt-daemon

# Debian 10 (Buster)
#
# We do not want to install qemu-system-gui, because this will pull in a lot of desktop related packages.
# Because apt installs recommended packages by default, the installation of libvirt-daemon will also pull in
# qemu-system-gui, because libvirt-daemon recommends qemu-kvm which depends on qemu-system-x86 which recommends
# qemu-system-gui which depends on libgtk-3-0 and other desktop packages.
apt install libvirt-clients libvirt-daemon qemu-system-gui- # watch out for recommended and suggested packages
# an alternative is to install without recommends, but then you have to install install recommended packages manually
apt install --no-install-recommends libvirt-clients libvirt-daemon
apt-get install --no-install-recommends qemu-kvm ovmf qemu-utils libvirt-daemon-system parted numad libxml2-utils netcat-openbsd dnsmasq-base
aptitude markauto qemu-kvm ovmf qemu-utils libvirt-daemon-system parted numad libxml2-utils netcat-openbsd dnsmasq-base


apt-get install bridge-utils
apt-get install --no-install-recommends virtinst

# Optional, for xen virtualisation hosts only
apt-get install xen-system-amd64
# NOTE: For xen guests you might also want to install xe-guest-utilities from ubuntu repositories

# Show os variants
# Ref.: man virt-install
apt install libosinfo-bin
osinfo-query os

# Add your user to kvm group if you want to use kvm in qemu:///session
# Ref.: ls -l /dev/kvm
adduser _USER_ kvm
adduser _USER_ libvirt


# Setup a bridge for VM network access
# Ref.: man bridge-utils-interfaces
vi /etc/network/interfaces
#
# Example configuration:
cat << 'EOF'

iface _IP4_ inet static
    address _IP4_/16
    gateway 10.0.0.1
    dns-nameservers 10.0.0.1

# Avoid conflicts with e.g. network manager
iface eth0 inet manual
    # (Optional) Increase MTU
    # Debian 8 (Jessie) or earlier option 'mtu' is not available when using the manual method
    # Ref.: https://askubuntu.com/a/279364
    #post-up ip link set dev eth0 mtu 9000
    # Since Debian 9 (Stretch) this workaround is not necessary anymore
    #mtu 9000

auto br0
iface br0 inet static
    bridge_ports eth0
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_maxwait 0
    # (Optional) Allow forwarding all traffic across the bridge to virtual machines
    # Ref.:
    #  https://wiki.libvirt.org/page/Networking
    #  https://bugzilla.redhat.com/show_bug.cgi?id=512206#c0
    #post-up iptables -I FORWARD -i br0 -m physdev --physdev-is-bridged -j ACCEPT
    #pre-down iptables -D FORWARD -i br0 -m physdev --physdev-is-bridged -j ACCEPT

auto br0:0
iface br0:0 inet static inherits _IP4_

EOF

# NOTE: You might want to suspend virtual machines on host shutdown
#       and start them after host has booted again. Do do so follow
#       libvirt_shutdown.sh!

# NOTE: If guests use larger MTUs than the host does, guests network might be broken.
