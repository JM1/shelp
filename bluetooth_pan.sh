#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Bluetooth PAN Network Setup with BlueZ 5.X
#
# References:
#  http://blog.fraggod.net/2015/03/28/bluetooth-pan-network-setup-with-bluez-5x.html
#  https://github.com/mk-fg/fgtk/blob/master/bt-pan
#  https://wiki.gentoo.org/wiki/Bluetooth

# On host do...

apt-get install isc-dhcp-server bridge-utils python rfkill wget bluetooth

cd /usr/local/sbin/
wget https://github.com/mk-fg/fgtk/raw/master/bt-pan
chmod u+x bt-pan

rfkill unblock bluetooth

cat << "EOF" >> /etc/network/interfaces

# Bluetooth PAN Network
auto br0
iface br0 inet static
    address 10.200.1.1
    netmask 255.255.0.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    bridge_maxwait 0

EOF

/etc/init.d/networking restart &

cat << "EOF" >> /etc/dhcp/dhcpd.conf

# Bluetooth PAN Network
subnet 10.200.0.0 netmask 255.255.0.0 {
        range 10.200.100.1 10.200.100.254;
        option domain-name "raspberrypi.home";
        option domain-name-servers 10.200.1.1;
        option broadcast-address 10.200.255.255;
        option subnet-mask 255.255.0.0;
        option routers 10.200.1.1;
        interface br0;
        authoritative;
}

EOF

service isc-dhcp-server restart

dash
cat << "EOF" > /etc/init.d/bt-pan
#!/bin/sh
#
#

### BEGIN INIT INFO
# Provides:          bt-pan
# Required-Start:    $network $syslog bluetooth
# Required-Stop:     $network $syslog bluetooth
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Bluetooth Network Aggregation Point 
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

test -f /usr/local/sbin/bt-pan || exit 0

BTPAN_DEFAULT="${BTPAN_DEFAULT:-/etc/default/bt-pan}"

# It is not safe to start if we don't have a default configuration...
if [ ! -f "$BTPAN_DEFAULT" ]; then
	echo "$BTPAN_DEFAULT does not exist! - Aborting..."
	exit 0
fi

. /lib/lsb/init-functions

# Read init script configuration
[ -f "$BTPAN_DEFAULT" ] && . "$BTPAN_DEFAULT"

NAME=bt-pan
DESC="Bluetooth PAN server"
# fallback to default config file
BTPAN_PID="${BTPAN_PID:-/var/run/bt-pan.pid}"

# single arg is -v for messages, -q for none
check_status()
{
	if [ ! -r "$BTPAN_PID" ]; then
		test "$1" != -v || echo "$NAME is not running."
		return 3
	fi
	if read pid < "$BTPAN_PID" && ps -p "$pid" > /dev/null 2>&1; then
		test "$1" != -v || echo "$NAME is running."
		return 0
	else
		test "$1" != -v || echo "$NAME is not running but $BTPAN_PID exists."
		return 1
	fi
}

case "$1" in
	start)
		log_daemon_msg "Starting $DESC" "$NAME"
		start-stop-daemon --start --quiet --background --make-pidfile --pidfile "$BTPAN_PID" \
			--exec /usr/bin/python -- \
			/usr/local/sbin/bt-pan --debug server $INTERFACE
		sleep 2

		if check_status -q; then
			log_end_msg 0
		else
			log_failure_msg "check syslog for diagnostics."
			log_end_msg 1
			exit 1
		fi
		;;
	stop)
		log_daemon_msg "Stopping $DESC" "$NAME"
		start-stop-daemon --stop --quiet --pidfile "$BTPAN_PID"
		log_end_msg $?
		rm -f "$BTPAN_PID"
		;;
	restart | force-reload)
		$0 stop
		sleep 2
		$0 start
		if [ "$?" != "0" ]; then
			exit 1
		fi
		;;
	status)
		echo -n "Status of $DESC: "
		check_status -v
		exit "$?"
		;;
	*)
		echo "Usage: $0 {start|stop|restart|force-reload|status}"
		exit 1 
esac

exit 0

EOF
exit

chmod a+x /etc/init.d/bt-pan

cat << "EOF" > /etc/default/bt-pan
INTERFACE="br0"
EOF

systemctl daemon-reload
systemctl disable bt-pan

cat << "EOF" > /etc/udev/rules.d/90-bluetooth.rules
# ID 0a12:0001 Cambridge Silicon Radio, Ltd Bluetooth Dongle (HCI mode)

SUBSYSTEMS=="usb", ACTION=="add", \
    ENV{ID_VENDOR_ID}=="0a12", ENV{ID_MODEL_ID}=="0001", \
    RUN+="/usr/sbin/service bt-pan start"

SUBSYSTEMS=="usb", ACTION=="remove", \
    ENV{ID_VENDOR_ID}=="0a12", ENV{ID_MODEL_ID}=="0001", \
    RUN+="/usr/sbin/service bt-pan stop"

EOF

service udev restart

# If you're using a bluetooth dongle connect it now...

bluetoothctl
 show
 discoverable on
 pairable on
 exit
 
# On Client (e.g. Samsung Galaxy Note 4) do...

# 1. Scan for bluetooth devices and pair them
# 2. Choose your paired device as an internet access point. If no such option is shown replug your host bluetooth dongle.

# Again on the host side do...
bluetoothctl
 trust D0:59:E4:EF:BD:C2 # Enter hw address of your client device
 discoverable off
 pairable off
 exit

# TODO: Enable routing on host side
# TODO: Find out why systemd hangs on boot when bluetooth dongle is plugged in during boot

exit # the end
