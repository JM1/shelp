#!/bin/sh
# vim:set tabstop=8 shiftwidth=4 expandtab:
# kate: space-indent on; indent-width 4;
#
# Copyright (c) 2024 Jakob Meng, <jakobmeng@web.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# Raspberry PI OS with Docker Pi-hole
#
# This script will integrate Docker Pi-hole into a Raspberry PI OS image. First, ensure that all prerequisites [0] are
# satisfied. Next, customize all configuration settings marked with a TODO below. Afterwards run this script to download
# and assemble a Raspberry PI OS image with Docker Pi-hole. Flash it to a (Micro) SD card, e.g. using Raspberry Pi
# Imager [1]. Finally, configure your router accordingly [0].
#
# Ref.:
# [0] rpi_pi-hole_docker_setup.md
# [1] https://www.raspberrypi.org/documentation/installation/

set -eu

error() {
    echo "ERROR: $*" 1>&2
}

warn() {
    echo "WARNING: $*" 1>&2
}

help() {
    cmd=$(basename "$0")
    cat << ____EOF
Usage: $cmd [OPTIONS] [RPI_OS_IMAGE_PATH_OR_URL]

Prepares a Raspberry PI OS image with Docker Pi-hole. Uses local image found at
RPI_OS_IMAGE_PATH_OR_URL or downloads it to the working directory otherwise.
Recent images for Raspberry PI OS can be found at:

  https://www.raspberrypi.com/software/operating-systems/

Raspberry Pi OS Lite is recommended, no desktop or other software is required.
Releases of Raspberry PI OS prior to Debian 12 (Bookworm) are not supported.

OPTIONS:
    -h, --help                    Print usage.
____EOF
}

if [ "$(id -u)" -ne 0 ]; then
    error "Please run as root"
    exit 125
fi

for cmd in \
    bunzip2 \
    curl \
    findmnt \
    losetup \
    mktemp \
    passwd \
    unxz
do
    if ! command -v "$cmd" >/dev/null; then
        error "$cmd not found"
        exit 1
    fi
done

rpi_os=""
rpi_os_default="https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-03-15/2024-03-15-raspios-bookworm-armhf-lite.img.xz"

while [ $# -ne 0 ]; do
    case "$1" in
        "-h"|"--help")
            help
            return 0
            ;;
        -*)
            error "Unknown flag: $1"
            return 1
            ;;
        *)
            if [ $# -ne 1 ]; then
                error "Unexpected flag(s): $*"
                return 1
            fi

            rpi_os="$1"
            ;;
    esac
    shift
done

[ -n "$rpi_os" ] || rpi_os=$rpi_os_default

if [ -e "$rpi_os" ]; then
    image="$rpi_os"
else
    if image="$(curl --write-out '%{filename_effective}' --request HEAD --location \
                --remote-name --remote-header-name --silent "$rpi_os")"
    then
        :
    elif [ "$?" -ne 18 ]; then
        # Failures other than partial downloads are fatal
        exit 1
    fi

    if [ ! -e "$image" ]; then
        curl --location --remote-name --remote-header-name "$rpi_os"
    fi
fi

pihole=""
prefix="rpi_os_pi-hole_$(date +%Y%m%d%H%M%S)"
case "$image" in
    *.img.bz2)
        pihole="${prefix}_[$(echo "$image" | sed -r 's/.img.bz2$//')].img"
        [ ! -e "$pihole" ] # assert
        bunzip2 --keep --stdout "$image" > "$pihole"
        ;;
    *.img.xz)
        pihole="${prefix}_[$(echo "$image" | sed -r 's/.img.xz$//')].img"
        [ ! -e "$pihole" ] # assert
        unxz --keep --stdout "$image" > "$pihole"
        ;;
    *.img)
        pihole="${prefix}_[$(echo "$image" | sed -r 's/.img$//')].img"
        [ ! -e "$pihole" ] # assert
        cp -a "$image" "$pihole"
        ;;
    *)
        error "$image has unknown file type"
        exit 1
        ;;
esac

[ -n "$pihole" ] && [ -e "$pihole" ] # assert

loopdev=""
bootmnt=""
rootmnt=""

cleanup() {
    if [ -n "$rootmnt" ]; then
        if findmnt --mountpoint "$rootmnt" >/dev/null; then
            umount "$rootmnt"
        fi
        rmdir "$rootmnt"
        rootmnt=""
    fi

    if [ -n "$bootmnt" ]; then
        if findmnt --mountpoint "$bootmnt" >/dev/null; then
            umount "$bootmnt"
        fi
        rmdir "$bootmnt"
        bootmnt=""
    fi

    if [ -n "$loopdev" ]; then
        losetup -d "$loopdev"
        loopdev=""
    fi
}

trap 'cleanup' INT EXIT

loopdev="$(losetup --find --show -P "$pihole")"

bootmnt="$(mktemp -d -t rpi-os-boot.XXXXXXXXXX)"
rootmnt="$(mktemp -d -t rpi-os-root.XXXXXXXXXX)"
[ -n "$bootmnt" ] && [ -d "$bootmnt" ] # assert
[ -n "$rootmnt" ] && [ -d "$rootmnt" ] # assert
mount "${loopdev}p1" "$bootmnt"
mount "${loopdev}p2" "$rootmnt"

if [ "$(cut -d. -f1 "$rootmnt/etc/debian_version")" -le 11 ]; then
    error "Raspberry PI OS releases prior to Debian 12 (Bookworm) are not supported."
    exit 1
fi

# TODO: Adapt network configuration.
#
# Delete the following NetworkManager configuration (first.nmconnection)
# when DHCP should be used instead of static ip address assignment.
cat << 'EOF' > "$rootmnt/etc/NetworkManager/system-connections/first.nmconnection"
# 2024 Jakob Meng, <jakobmeng@web.de>
#
# Network configuration
#
# This example assigns a static ip address, similar to
# $> nmcli con add con-name "first" ifname eth0 type ethernet ip4 192.168.0.2/16 gw4 192.168.0.1
# $> nmcli con mod "first" ipv4.dns "1.1.1.1"
# $> nmcli con mod "first" ipv6.address "fd00::192:168:0:2/128"
# $> nmcli con mod "first" ipv6.dns "2606:4700:4700::1111"
# $> nmcli con up "first"
#
# Ref.: https://www.networkmanager.dev/docs/api/latest/nm-settings-nmcli.html
[connection]
id=first
type=ethernet
interface-name=eth0

[ethernet]

[ipv4]
address1=192.168.0.2/16,192.168.0.1
dns=1.1.1.1;
method=manual

[ipv6]
addr-gen-mode=default
address1=fd00::192:168:0:2/128
dns=2606:4700:4700::1111;
method=auto
EOF
chmod u=rw,g=,o= "$rootmnt/etc/NetworkManager/system-connections/first.nmconnection"

# Disable persistent logging in journald to reduce sd card wear and increase its lifespan (optional)
# Ref.: /usr/share/doc/systemd/README.Debian.gz
rm -rf "$rootmnt/var/log/journal"

# Enable remote access using SSH.
touch "$bootmnt/ssh"

mkdir "$rootmnt/home/pi/.ssh"
chown 1000:1000 "$rootmnt/home/pi/.ssh"
chmod u=rwx,g=,o= "$rootmnt/home/pi/.ssh"

# TODO: Replace with your SSH keys.
cat << 'EOF' > "$rootmnt/home/pi/.ssh/authorized_keys"
ssh-rsa AAAAB3NzaC1yc2E...
EOF
chmod u=rw,g=,o= "$rootmnt/home/pi/.ssh/authorized_keys"
chown 1000:1000 "$rootmnt/home/pi/.ssh/authorized_keys"

# Disable logins except ssh (optional).
passwd --lock pi --root "$rootmnt" >/dev/null

# Disable password authentication for SSH logins.
cat << 'EOF' > "$rootmnt/etc/ssh/sshd_config.d/99-disable-password-authentication.conf"
# 2024 Jakob Meng, <jakobmeng@web.de>
PasswordAuthentication no
EOF

# Change hostname.
#
# TODO: Adapt hostname (optional).
cat << 'EOF' > "$rootmnt/etc/hostname"
pihole
EOF
#
# TODO: Adapt hostname (optional).
sed -i -e 's/raspberrypi$/pihole/g' "$rootmnt/etc/hosts"

# Prepare bootstrap steps such as package installation.
# TODO: Analyse entries marked as optional.
cat << 'EOF' > "$rootmnt/usr/local/bin/bootstrap.sh"
#!/bin/bash
# 2021-2024 Jakob Meng, <jakobmeng@web.de>

set -eux

# Disable bluetooth and wifi (optional)
# NOTE: Do not block wifi if you are using wifi instead of ethernet!
rfkill block all
# or
#rfkill block bluetooth

# Disable swap to reduce sd card wear and increase its lifespan (optional)
apt-get remove -y dphys-swapfile

# Upgrade all installed packages
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# Install tools
apt-get install -y vim screen aptitude fzf git curl

# Install Docker runtime and Docker Compose
apt-get install -y docker.io docker-compose

# Set up unattended upgrades
apt-get install -y unattended-upgrades

# Ref.: /var/lib/dpkg/info/unattended-upgrades.postinst
cp -rav /usr/share/unattended-upgrades/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
# Synchronize debconf database with locales' config which will help during
# package updates because debconf will not complain about config changes
dpkg-reconfigure -f noninteractive unattended-upgrades

# Enable service which delays shutdown or reboots during upgrades
systemctl is-enabled unattended-upgrades.service || systemctl enable unattended-upgrades.service

# Reboot after updates if required to apply changes
sed -i -e 's/\/\/Unattended-Upgrade::Automatic-Reboot "false";/Unattended-Upgrade::Automatic-Reboot "true";/g' \
    /etc/apt/apt.conf.d/50unattended-upgrades

# Upgrade all packages
grep -q '^[[:space:]]*"origin=\*"' /etc/apt/apt.conf.d/50unattended-upgrades ||
    sed -z -i -e 's/\nUnattended-Upgrade::Origins-Pattern {\n/'\
'\nUnattended-Upgrade::Origins-Pattern {\n        "origin=\*";\n/g' \
        /etc/apt/apt.conf.d/50unattended-upgrades

touch /var/lib/bootstrapped

# Reboot to apply changes
reboot
EOF
chmod u=rwx,g=rx,o=rx "$rootmnt/usr/local/bin/bootstrap.sh"

cat << 'EOF' > "$rootmnt/etc/systemd/system/bootstrap.service"
# 2023 Jakob Meng, <jakobmeng@web.de>
[Unit]
Wants=network-online.target
After=network-online.target

StartLimitBurst=3
StartLimitIntervalSec=infinity

ConditionPathExists=!/var/lib/bootstrapped

[Service]
Type=oneshot
ExecStart=/usr/local/bin/bootstrap.sh
RemainAfterExit=yes
# Retry because network configuration might not be completed despite Wants=network-online.target
Restart=on-failure
RestartSec=15s

[Install]
WantedBy=multi-user.target
EOF
chmod u=rw,g=r,o=r "$rootmnt/etc/systemd/system/bootstrap.service"
ln -s "/etc/systemd/system/bootstrap.service" "$rootmnt/etc/systemd/system/multi-user.target.wants/bootstrap.service"

# Prepare Docker Pi-hole.
mkdir -p "$rootmnt/opt/pihole"
# TODO: Adapt Pi-hole's network configuration and Watchtower's configuration in Docker Compose config.
#
# NOTE: Self-updating functionality triggered by Watchtower is experimental and might break Pi-hole! For example, 
# updates to the Docker image might require changes of the Docker Compose config, e.g. when deprecated variables have
# been removed. If you do not want to enable updates using Watchtower, remove the `watchtower:` key and its content
# from the Docker Compose config below.
#
cat << 'EOF' > "$rootmnt/opt/pihole/docker-compose.yml"
version: "3"

# https://github.com/pi-hole/docker-pi-hole/blob/master/README.md

services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    network_mode: "host"

    # Pi-hole environment variables
    # Ref.: https://github.com/pi-hole/docker-pi-hole#environment-variables
    environment:
      TZ: 'Europe/Berlin'
      # WEBPASSWORD: 'set a secure password here or it will be random'
      DNSSEC: 'true'

      # IPv4 address of Raspberry Pi
      FTLCONF_LOCAL_IPV4: '192.168.0.2'

      # IPv6 address of Raspberry Pi
      # Mandatory to block IPv6 ads
      FTLCONF_LOCAL_IPV6: 'fd00::192:168:0:2'

      # Enable DHCP for IPv4? Only required if your router is not
      # (or cannot be) configured to announce Pi-hole as name server.
      # See section on router setup below for more info.
      #DHCP_ACTIVE: 'false'
      #DHCP_START: '192.168.0.101'
      #DHCP_END: '192.168.0.254'
      #DHCP_ROUTER: '192.168.0.1' # mandatory if DHCP server is enabled
      #DHCP_LEASETIME: '24'

      # DHCPv6 Rapid Commit
      # Ref.: https://discourse.pi-hole.net/t/option-enable-dhcp-rapid-commit-fast-address-assignment/17079
      #DHCP_rapid_commit: 'true'

      # Enable DHCPv6 for IPv6? Only required if your router is not
      # (or cannot be) configured to announce Pi-hole as name server.
      # See section on router setup below for more info.
      #DHCP_IPv6: 'true'

      # Increase time (in milliseconds) Pi-hole scripts in /etc/cont-finish.d can take before S6 sends a KILL signal,
      # if Pi-hole's container fails to start with error messages like e.g.
      #   s6-supervise pihole-FTL: warning: finish script lifetime reached maximum value - sending it a SIGKILL
      #   s6-supervise cron: warning: finish script lifetime reached maximum value - sending it a SIGKILL
      #S6_KILL_FINISH_MAXTIME: 30000

    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole/:/etc/pihole/'
      - './etc-dnsmasq.d/:/etc/dnsmasq.d/'
      # run `touch ./var-log/pihole.log` first unless you like errors
      # - './var-log/pihole.log:/var/log/pihole.log'

    # Recommended but not required (DHCP needs NET_ADMIN)
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      - NET_ADMIN

    # Autostart Docker Pi-hole at system boot
    # Ref.: https://serverfault.com/a/649835/373320
    restart: unless-stopped

  # Remove watchtower key and its contents if you do not want to enable Docker image updates
  watchtower:
    container_name: watchtower
    image: containrrr/watchtower:latest

    # Watchtower environment variables
    # Ref.: https://containrrr.dev/watchtower/arguments/
    environment:
      TZ: 'Europe/Berlin'
      WATCHTOWER_CLEANUP: 'true'
      WATCHTOWER_INCLUDE_RESTARTING: 'true'
      WATCHTOWER_ROLLING_RESTART: 'true'
      WATCHTOWER_TIMEOUT: '30s'

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

    # Autostart Watchtower at system boot
    restart: unless-stopped
EOF

cat << 'EOF' > "$rootmnt/etc/systemd/system/pihole.service"
# 2024 Jakob Meng, <jakobmeng@web.de>
[Unit]
Wants=network-online.target docker.service
After=network-online.target docker.service

[Service]
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose stop
WorkingDirectory=/opt/pihole
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
chmod u=rw,g=r,o=r "$rootmnt/etc/systemd/system/pihole.service"
ln -s "/etc/systemd/system/pihole.service" "$rootmnt/etc/systemd/system/multi-user.target.wants/pihole.service"

cleanup
trap - INT EXIT

echo "Image has been written to: $pihole"
