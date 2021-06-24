#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Bind Apache2 to VMware NICs
#

sudo -s

# Make sure Apache2 is started after VMware NICs have been setup.
cat << 'EOF' | patch
--- /etc/init.d/apache2.orig    2012-05-28 22:40:21.000000000 +0200
+++ /etc/init.d/apache2         2013-01-14 09:57:00.085771286 +0100
@@ -1,8 +1,8 @@
 #!/bin/sh
 ### BEGIN INIT INFO
 # Provides:          apache2
-# Required-Start:    $local_fs $remote_fs $network $syslog $named
-# Required-Stop:     $local_fs $remote_fs $network $syslog $named
+# Required-Start:    $local_fs $remote_fs $network $syslog $named vmware
+# Required-Stop:     $local_fs $remote_fs $network $syslog $named vmware
 # Default-Start:     2 3 4 5
 # Default-Stop:      0 1 6
 # X-Interactive:     true
EOF

cat << 'EOF' >> /etc/apache2/ports.conf
# ATTENTION: 
# VMware networks are not available at boot, so apache2 will fail to start.
# A Workaround is to edit /etc/init.d/apache2 to require "vmware" at boot.

# VMware networks for e.g. Windows Development VM
Listen 10.100.1.1:80
Listen 10.100.2.1:80

<IfModule ssl_module>
    # VMWare networks for e.g. Windows Development VM
    Listen 10.100.1.1:443
    Listen 10.100.2.1:443
</IfModule>

<IfModule mod_gnutls.c>
    # VMWare networks for e.g. Windows Development VM
    Listen 10.100.1.1:443
    Listen 10.100.2.1:443
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF

# Remove unnecessary 'Listen' directives
vi /etc/apache2/ports.conf

reboot

exit # the end
