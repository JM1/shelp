#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed

########################################
#
# Higher VNC resolution for virtual machines
#
virsh edit ${VM}
# Change
#  <video>
#    <model type='cirrus' ... />
#  </video>
# to
#  <video>
#    <model type='vga' ... />
#  </video>
# or
#  <video>
#    <model type='virtio' vram='65536' ... />
#  </video>

# Within virtual machine do..
# ..for X:
cat << 'EOF' > $HOME/.config/autostart/resolution.desktop 
[Desktop Entry]
Version=1.0
Name=setup desktop resolution
Exec=/usr/bin/xrandr --output Virtual-0 --mode 1680x1050
Icon=redshift
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
EOF

# ..for Wayland:
cat << 'EOF' > $HOME/.config/monitors.xml
<monitors version="2">
  <configuration>
    <logicalmonitor>
      <x>0</x>
      <y>0</y>
      <scale>1</scale>
      <primary>yes</primary>
      <monitor>
        <monitorspec>
          <connector>Virtual-1</connector>
          <vendor>unknown</vendor>
          <product>unknown</product>
          <serial>unknown</serial>
        </monitorspec>
        <mode>
          <width>1680</width>
          <height>1050</height>
          <rate>59.954746246337891</rate>
        </mode>
      </monitor>
    </logicalmonitor>
  </configuration>
</monitors>
EOF

# ..for GDM3 (Wayland or X):
cp -raiv $HOME/.config/monitors.xml /var/lib/gdm3/.config/monitors.xml
chown Debian-gdm.Debian-gdm /var/lib/gdm3/.config/monitors.xml
systemctl restart gdm

########################################
#
# Enable Spice GL passthrough / GL acceleration (virgl)
# NOTE: This has not been tested successfully yet!
# NOTE: OpenGL acceleration is currently local only (it has to go through a Unix socket), not via network!
# NOTE: OpenGL acceleration needs guest support. It’s currently limited to recent linux distributions (for example Fedora 24).
# NOTE: There are problems with NVIDIA's binary driver, see https://bugzilla.redhat.com/show_bug.cgi?id=1460804
# Ref.:
#  https://www.spice-space.org/spice-user-manual.html
#  https://bugzilla.redhat.com/show_bug.cgi?id=1337290
#  https://wiki.archlinux.org/index.php/QEMU#virtio

# NOTE: The following is perhaps not needed anymore with recent libvirt releases?!
cat << 'EOF' | patch -p0 -d /
--- /etc/libvirt/qemu.conf.orig	2019-06-17 19:05:40.000000000 +0200
+++ /etc/libvirt/qemu.conf	2019-09-03 08:00:26.000000000 +0200
@@ -495,6 +495,9 @@
 #   "/dev/infiniband/umad1",
 #   "/dev/infiniband/uverbs0"
 
+# Enable Spice GL passthrough
+# Ref.: https://bugzilla.redhat.com/show_bug.cgi?id=1337290
+cgroup_device_acl = [ "/dev/dri/renderD128", "/dev/kvm" ]
 
 # The default format for QEMU/KVM guest save images is raw; that is, the
 # memory from the domain is dumped out directly to a file.  If you have

EOF
# NOTE: You have to add more devices to cgroup_device_acl perhaps!
systemctl restart libvirtd.service

virsh edit ${VM}
# Add <gl enable="yes"/> to <graphics type="spice">
# Set <listen type='none'/> in <graphics type='spice'>
# Add <acceleration accel3d='yes'/> to <model type='virtio'>


# Inside linux virtual machine
dmesg | grep drm
# Output should be e.g.
#  [drm] pci: virtio-vga detected
#  [drm] virgl 3d acceleration enabled

########################################
