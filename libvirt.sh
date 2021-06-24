#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Creating a virtual machine using libvirt and QEMU/KVM
#
# Prerequisites:
#  - Debian 8 (Jessie) installation, e.g. as described in debian_setup.sh including
#     + 'Virtualisation configuration'
#
# References:
# [1] http://wiki.ubuntuusers.de/virsh
# [2] man virt-install

# Connect to vm host
ssh -X -L localhost:55900:localhost:5900 jakob@TheoInf1LiUb.HBRS_INTERN

# (Optional) Enable debugging output
export LIBVIRT_DEBUG=1

# Execute on vm host
VM=$(whoami)_vm
virt-install \
    --connect qemu:///system \
    #--connect qemu:///session \
    #--boot uefi \
    --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
    #--boot loader=/usr/share/OVMF/OVMF_CODE.fd,loader_ro=yes,loader_type=pflash,nvram_template=/usr/share/OVMF/OVMF_VARS.fd \
    # for UEFI on ARM64
    #--boot loader=/usr/share/qemu-efi/QEMU_EFI.fd,loader_ro=yes,loader_type=pflash \
    #--boot loader=/usr/share/AAVMF/AAVMF_CODE.fd,loader_ro=yes,loader_type=pflash,nvram_template=/usr/share/AAVMF/AAVMF_VARS.fd \
    --machine q35 \
    --virt-type kvm \
    #--connect xen:/// \
    #--virt-type xen \
    #--paravirt \
    --name ${VM} \
    --ram 8096 \
    #--memballoon virtio,autodeflate=on \
    #--cpu host \ # crashs Windows 10 Installer
    --vcpus=4 \
    # Nowadays the distinction between --os-type and --os-variant is pointless
    # Ref.: https://github.com/virt-manager/virt-manager/commit/a722eeac78d2db9e56703f5555bb48cd66e5b7a7
    #--os-type=linux
    #--os-type=windows
    #
    #--os-variant ubuntutrusty \
    #--os-variant debianwheezy \
    #--os-variant debian9 \
    # Specifying os variant is HIGHLY RECOMMENDED, as it can greatly increase performance by specifying virtio
    # among other guest tweaks. It also enables support for QEMU Guest Agent by adding a virtio-serial channel.
    # Ref.: man virt-install
    --os-variant win10 \
    # Without 'serial=...' no links under '/dev/disk/by-id/' are generated (NOTE: long serials get truncated)!
    #--disk path=/dev/disk/by-id/usb-SanDisk_Extreme_AA011217122315043254-0\:0,serial=disk_a,bus=virtio \
    --disk path=/var/lib/libvirt/images/${VM}_disk_a.img,size=250,serial=disk_a,bus=virtio \
    #--disk path=/var/lib/libvirt/${VM}_disk_a.img,size=25,serial=disk_a \
    #--disk path=~/.local/share/libvirt/images/${VM}_disk_a.qcow2,size=10,serial=disk_a,bus=virtio \
    #--disk /vm/software/Microsoft\ Windows\ 10/SW_DVD9_Win_Pro_Ent_Edu_N_10_1809_64-bit_German_MLF_X21-96513.ISO,device=cdrom,bus=ide \
    #--disk /vm/software/Microsoft\ Windows\ 10/SW_DVD9_Win_Pro_Ent_Edu_N_10_1809_64-bit_German_MLF_X21-96513.ISO,device=cdrom \
    #--disk /vm/software/virtio-win-0.1.141.iso,device=cdrom,bus=ide \
    #--disk /vm/software/virtio-win-0.1.141.iso,device=cdrom \
    #--network=bridge:br0,model=virtio,mac=00:00:00:00:00:01 \
    --network=bridge:br0,model=virtio,mac=RANDOM \
    #--network bridge=virbr0 \
    #--network user \
    --noautoconsole \
    --check-cpu \
    #--cdrom /stella/tmp/ubuntu-14.04.2-server-amd64.iso \
    #--cdrom /stella/tmp/debian-8.4.0-amd64-netinst.iso \
    --location=http://ftp.debian.org/debian/dists/stable/main/installer-amd64/ \
    # extra kernel args, e.g. 'priority=low' for Debian's 'Expert Install'
    --extra-args='priority=low' \
    # Additional options
    #--graphics vnc,listen=127.0.0.1,keymap=de,password=foobar \
    --graphics spice \
    --console pty,target_type=virtio \
    --sound ich9 \
    # Permanently attach usb device (required for boot from usb), find id with 'lsusb'
    --controller usb,model=nec-xhci \
    --host-device 0x1b1c:0x1a90 \
    # Show boot menu
    --boot menu=on,... \
    #--import
    #--print-xml

# Example: Windows 10 @ UEFI
VM=win10test
virt-install \
    --connect qemu:///session \
    --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
    --machine q35 \
    --virt-type kvm \
    --name ${VM} \
    --ram 8096 \
    --vcpus=4 \
    --os-variant win10 \
    --disk /vm/software/Microsoft\ Windows\ 10/SW_DVD9_Win_Pro_Ent_Edu_N_10_1809_64-bit_German_MLF_X21-96513.ISO,device=cdrom \
    --disk path=~/.local/share/libvirt/images/${VM}.qcow2,size=40,serial=disk_a,bus=virtio \
    --disk /vm/software/virtio-win-0.1.141.iso,device=cdrom \
    --network user \
    --noautoconsole \
    --check-cpu \
    --graphics spice \
    --console pty,target_type=virtio \
    --controller usb,model=nec-xhci \
    --sound ich9

# Example: USB Disk
VM=SanDisk_Extreme
virt-install \
    --connect qemu:///session \
    --boot loader=/usr/share/OVMF/OVMF_CODE.fd \
    --machine q35 \
    --virt-type kvm \
    --name ${VM} \
    --ram 8096 \
    --vcpus=4 \
    --os-variant debian10 \
    --disk path=/dev/disk/by-id/usb-SanDisk_Extreme_AA011217122315043254-0\:0,serial=disk_a,bus=virtio \
    --network bridge=virbr0 \
    --noautoconsole \
    --check-cpu \
    --graphics spice \
    --console pty,target_type=virtio \
    --sound ich9 \
    --import

# NOTE: Disable writethrough (default) disk cache because this actually hurts performance!
# Ref.: http://www.ilsistemista.net/index.php/virtualization/11-kvm-io-slowness-on-rhel-6.html
virsh edit ${VM}
# Change 
#  <driver name='qemu' type='raw'/>
# to
#  <driver name='qemu' type='raw' cache='none' io='native'/>

# NOTE: Use qcow2 format with preallocation=full for disk images to improve performance,
#       raw format does not allow preallocation!
# Ref.: http://www.ilsistemista.net/index.php/virtualization/11-kvm-io-slowness-on-rhel-6.html

# If underlying filesystem is e.g. btrfs then disable copy-on-write to improve performance.
# Ref.: btrfs_cow.sh
# NOTE: Disabling copy-on-write will disable data checksums for disk image!
# NOTE: Disabling copy-on-write works only for newly created files, thus we make a fresh copy of the vm disk image!

chattr +C /stella/vm/${VM}/
mv -i /stella/vm/${VM}/disk_a.img /stella/vm/${VM}/disk_a.img.orig
cp -raiv /stella/vm/${VM}/disk_a.img.orig /stella/vm/${VM}/disk_a.img
rm /stella/vm/${VM}/disk_a.img.orig

# Prepare qemu-guest-agent
# Ref.: https://serverfault.com/a/691616
virsh edit ${VM}
# Add virtio serial port to domain XML under <devices>
cat << 'EOF'
<channel type="unix">
  <source mode="bind"/>
  <target type="virtio" name="org.qemu.guest_agent.0"/>
</channel>
EOF

# Execute on client
vncviewer localhost:55900 # Password is "foobar", see above!

# Execute in VM
apt-get install qemu-guest-agent

# Execute on host verify agent connectivity
virsh qemu-agent-command ${VM} '{"execute":"guest-network-get-interfaces"}'

########################################
# Bridged network interfaces for qemu:///session domains
# Ref.: /usr/share/doc/libvirt-daemon/README.Debian.gz

virsh net-autostart default

setcap cap_net_admin+ep /usr/lib/qemu/qemu-bridge-helper
mkdir /etc/qemu
cat << 'EOF' >> /etc/qemu/bridge.conf
allow virbr0
EOF

virt-install \
    --connect qemu:///session \
    --network bridge=virbr0 \
    ...

########################################
#
# Connect via serial
#
virsh console ${VM}

########################################
#
# Edit vm's config
#
vi /etc/libvirt/qemu/${VM}.xml
# Reload vm's config
virsh define /etc/libvirt/qemu/${VM}.xml

# Or directly edit and reload vm's config
virsh edit ${VM}

########################################
#
# Send commands to QEMU monitor
#
virsh qemu-monitor-command --hmp ${VM} 'sendkey alt-sysrq-r'

########################################
# Attach usb device
#
XML=...
cat << 'EOF' >> "${XML}"
<!-- Corsair Flash Voyager GT -->
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <vendor id='0x1b1c'/>
    <product id='0x1a90'/>
  </source>
</hostdev>
EOF

cat << 'EOF' >> "${XML}"
<!--  SanDisk Corp. SDCZ80 Flash Drive -->
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <vendor id='0x0781'/>
    <product id='0x5580'/>
  </source>
</hostdev>
EOF

virsh attach-device ${VM} "${XML}"
virsh detach-device ${VM} "${XML}"

########################################
#
# Attach device, e.g. a physical disk or an encrypted-and-opened device
#
# References:
#  https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_administration_guide/sect-virtualization-virtualized_block_devices-adding_storage_devices_to_guests

virsh attach-disk ${VM} /dev/sdb vdb --cache none --config
# this will add a config section like written below to vm config:
#  <disk type='block' device='disk'>
#    <driver name='qemu' type='raw' cache='none'/>
#    <source dev='/dev/sdb'/>
#    <target dev='vdb' bus='virtio'/>
#  </disk>

# now (re)start vm to load new vm config

# NOTE: "If the guest is running, and you want the new device
#        to be added temporarily until the guest is destroyed,
#        omit the --config option"
# NOTE: There is a resolved-in-sid-only bug in Debian 9 (Stretch) which prevents adding devices online,
#       see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=805002

####################
# an alternative way, but offline only
XML=/PATH/TO/XML...
cat << 'EOF' >> "${XML}"
<disk type='block' device='disk'>
  <driver name='qemu' type='raw' cache='none'/>
  <source dev='/dev/sdb'/>
  <target dev='vdb' bus='virtio'/>
</disk>
EOF

virsh attach-device ${VM} "${XML}"
# now (re)start vm to load new vm config
virsh detach-device ${VM} "${XML}"

########################################
#
# Create and attach an additional virtual disk
#
qemu-img create -f raw -o nocow=on disk_b.img 1750G 
# nocow=on for better perf. on btrfs, see 'man qemu-img'
vi /etc/libvirt/qemu/*.xml
# Add:
#  <disk type='file' device='disk'>
#    <driver name='qemu' type='raw'/>
#    <source file='/var/lib/libvirt/images/another_disk.img'/>
#    <target dev='vdb' bus='virtio'/>
#    <serial>disk_b</serial>
#  </disk>

########################################
#
# Increase boot menu timeout
#
virsh edit ${VM}
# Change
#  <os>
#    <bootmenu enable='yes'/>
#  </os>
# to
#  <os>
#    <bootmenu enable='yes' timeout='30000' />
#  </os>

########################################
#
# Autostart a VM at boot
#
virsh autostart ${VM}
virsh autostart --disable ${VM}

########################################
#
# Shutting down, rebooting and force-shutdown
#
# Ref.: https://docs.fedoraproject.org/en-US/Fedora/18/html/Virtualization_Administration_Guide/ch15s06.html

virsh shutdown ${VM}
virsh reboot ${VM}
virsh destroy ${VM} # immediate ungraceful shutdown

########################################
# Fix high host cpu load in idle for Windows 10 (since update 1803) guests aka
# Windows 10 (>=1803) consumes 30% of host cpu in idle
#
# Ref.:
# [1] https://bugzilla.redhat.com/show_bug.cgi?id=1644693
# [2] https://bugzilla.redhat.com/show_bug.cgi?id=1738244
# [3] https://faq.inf.h-brs.de/doku/fb02/server/openstack/bugs-and-work-arounds/windows-10-consumes-30-cpu-in-idle
# [4] https://libvirt.org/formatdomain.html

virsh edit ${VM}
# add missing attributes:
#  <domain type='kvm'>
#    ...
#    <features>
#      <hyperv>
#        <relaxed state='on'/>
#        <vapic state='on'/>
#        <spinlocks state='on' retries='8191'/>
#        <vpindex state='on'/>
#        <synic state='on'/>
#        <stimer state='on'/>
#      </hyperv>
#    </features>
#    ...
#    <clock offset='localtime'>
#      <timer name='rtc' tickpolicy='catchup'/>
#      <timer name='pit' tickpolicy='delay'/>
#      <timer name='hpet' present='no'/>
#      <timer name='hypervclock' present='yes'/>
#    </clock>
#    ...
#  </domain>

########################################
