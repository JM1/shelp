#!/bin/sh
# vim:set tabstop=8 shiftwidth=4 expandtab:
# kate: space-indent on; indent-width 4;
#
# Copyright (c) 2024-2026 Jakob Meng, <jakobmeng@web.de>
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
Releases of Raspberry PI OS prior to Debian 13 (Trixie) are not supported.

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
rpi_os_default="https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2025-12-04/2025-12-04-raspios-trixie-armhf-lite.img.xz"

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

# HACK: Rename vfat partition to ensure the NoCloud datasource volume label is set to cidata, as required by cloud-init.
# Ref.: https://github.com/RPi-Distro/rpi-cloud-init-mods/issues/2
fatlabel "${loopdev}p1" "cidata"

bootmnt="$(mktemp -d -t rpi-os-boot.XXXXXXXXXX)"
rootmnt="$(mktemp -d -t rpi-os-root.XXXXXXXXXX)"
[ -n "$bootmnt" ] && [ -d "$bootmnt" ] # assert
[ -n "$rootmnt" ] && [ -d "$rootmnt" ] # assert
mount "${loopdev}p1" "$bootmnt"
mount "${loopdev}p2" "$rootmnt"

if [ "$(cut -d. -f1 "$rootmnt/etc/debian_version")" -le 12 ]; then
    error "Raspberry PI OS releases prior to Debian 13 (Trixie) are not supported."
    exit 1
fi

# HACK: Wait for clock synchronization before running the final cloud-init stage, which may run package updates.
# Ref.: https://github.com/RPi-Distro/rpi-cloud-init-mods/issues/3
mkdir -p "$rootmnt/etc/systemd/system/sysinit.target.wants"
ln -s "/usr/lib/systemd/system/systemd-time-wait-sync.service" "$rootmnt/etc/systemd/system/sysinit.target.wants/systemd-time-wait-sync.service"

# Write cloud-init network configuration.
# TODO: Customize cloud-init network configuration.
#
# Delete the following cloud-init network configuration (network-config)
# when DHCP should be used instead of static ip address assignment.
cat << 'EOF' >> "$bootmnt/network-config"
# 2026 Jakob Meng, <jakobmeng@web.de>
# Network configuration
# Ref.:
# https://cloudinit.readthedocs.io/en/latest/reference/network-config-format-v2.html
# https://netplan.readthedocs.io/en/latest/netplan-yaml/
# https://www.raspberrypi.com/news/cloud-init-on-raspberry-pi-os/

network:
  version: 2

  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
      accept-ra: false

      addresses:
      - 192.168.0.2/16
      - fd00::192:168:0:2/128

      nameservers:
        addresses:
        - 1.1.1.1
        - 2606:4700:4700::1111
      routes:
      - to: 0.0.0.0/0
        via: 192.168.0.1
      - to: ::/0
        via: fd00::192:168:0:1/128

# Connect Raspberry Pi to a Wi-Fi network
#  wifis:
#    wlan0:
#      dhcp4: false
#      dhcp6: false
#      accept-ra: false
#      optional: true
#      access-points:
#        "network_ssid_name":
#          password: "**********"
EOF

# Write cloud-init configuration.
# TODO: Customize cloud-init configuration.
cat << 'EOF' >> "$bootmnt/user-data"
#cloud-config
# 2026 Jakob Meng, <jakobmeng@web.de>
# Ref.: https://cloudinit.readthedocs.io/en/latest/reference/modules.html

# Customize hostname (optional).
hostname: pihole

# Disable password authentication for SSH logins.
ssh_pwauth: false

users:
- name: pi

  # Disable logins except ssh (optional).
  lock_passwd: true

  # TODO: Replace with your SSH keys.
  ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2E...

# Upgrade all installed packages
package_reboot_if_required: true
package_update: true
package_upgrade: true

packages:
#
# Install tools
- vim
- screen
- aptitude
- fzf
- git
- curl
#
# Install Docker runtime and Docker Compose
- docker.io
- docker-compose
#
# Install unattended upgrades
- unattended-upgrades

write_files:
# Prepare Docker Pi-hole.
#
# The following docker-compose.yml file configures Docker Pi-hole with host networking mode to allow DHCP responses.
# See Docker DHCP and Network Modes [0] for rationale and other networking modes. You may also refer to the official
# example Docker Compose configuration (without Watchtower) [1]. Watchtower [2] will be used to automate base image
# updates of Pi-hole's Docker container.
#
# TODO: Customize Pi-hole's network configuration and Watchtower's configuration in Docker Compose config.
#
# NOTE: Self-updating functionality triggered by Watchtower is experimental and might break Pi-hole! For example,
# updates to the Docker image might require changes of the Docker Compose config, e.g. when deprecated variables have
# been removed. If you do not want to enable updates using Watchtower, remove the `watchtower:` key and its content
# from the Docker Compose config below.
#
# Ref.:
# [0] https://docs.pi-hole.net/docker/dhcp/
# [1] https://github.com/pi-hole/docker-pi-hole/blob/master/README.md#quick-start
# [2] https://containrrr.dev/watchtower/
#
- content: |
    # More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/

    services:
      pihole:
        container_name: pihole
        image: pihole/pihole:latest

        ports:
          - "53:53/tcp"
          - "53:53/udp"
          - "80:80/tcp"
          - "443:443/tcp"
        #
        # Use host networking mode instead when enabling DHCP for IPv4 or IPv6
        #network_mode: "host"

        # Pi-hole environment variables
        # Ref.: https://github.com/pi-hole/docker-pi-hole#environment-variables
        environment:
          TZ: 'Europe/Berlin'

          # Set a password to access the web interface. Not setting one will result in a random password being assigned
          #FTLCONF_webserver_api_password: 'correct horse battery staple'

          FTLCONF_dns_dnssec: 'true'

          # For Docker's default bridge, delete or comment out when using host networking mode
          FTLCONF_dns_listeningMode: 'ALL'
          # https://github.com/pi-hole/docker-pi-hole/pull/1946

          # IPv4 address of Raspberry Pi
          #FTLCONF_dns_reply_host_force4: 'true'
          #FTLCONF_dns_reply_host_IPv4: '192.168.0.2'

          # IPv6 address of Raspberry Pi
          #FTLCONF_dns_reply_host_force6: 'true'
          #FTLCONF_dns_reply_host_IPv6: 'fd00::192:168:0:2'

          # Enable DHCP for IPv4? Only required if your router is not
          # (or cannot be) configured to announce Pi-hole as name server.
          # See section on router setup below for more info.
          #FTLCONF_dhcp_active:    'true'
          #FTLCONF_dhcp_start:     '192.168.0.101' # first IPv4 address used for DHCP
          #FTLCONF_dhcp_end:       '192.168.0.254' # last IPv4 address used for DHCP
          #FTLCONF_dhcp_router:    '192.168.0.1'    # router ip, mandatory if DHCP server is enabled
          #FTLCONF_dhcp_leaseTime: '64'

          # DHCPv6 Rapid Commit
          # Ref.: https://discourse.pi-hole.net/t/option-enable-dhcp-rapid-commit-fast-address-assignment/17079
          #FTLCONF_dhcp_rapidCommit: 'true'

          # Enable DHCPv6 for IPv6? Only required if your router is not
          # (or cannot be) configured to announce Pi-hole as name server.
          # See section on router setup below for more info.
          #FTLCONF_dhcp_ipv6: 'true'

        # Volumes store your data between container upgrades
        volumes:
          - './etc-pihole/:/etc/pihole/'

        cap_add:
          # Required if you are using Pi-hole as your DHCP server, else not needed
          # Ref.: https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
          - NET_ADMIN
          # Required if you are using Pi-hole as your NTP client to be able to set the host's system time
          - SYS_TIME
          # Optional, if Pi-hole should get some more processing time
          - SYS_NICE

        # Autostart Docker Pi-hole at system boot
        # Ref.: https://serverfault.com/a/649835/373320
        restart: unless-stopped

      # TODO: Remove watchtower key and its contents if you do not want to enable Docker image updates
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
  path: /opt/pihole/docker-compose.yml
- content: |
    # 2024-2026 Jakob Meng, <jakobmeng@web.de>
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
  path: /etc/systemd/system/pihole.service
#
# Prepare unattended upgrades
- content: |
    #!/bin/bash
    # 2021-2026 Jakob Meng, <jakobmeng@web.de>
    # Set up unattended upgrades
    # Ref.: /var/lib/dpkg/info/unattended-upgrades.postinst

    set -eux

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

    systemctl restart unattended-upgrades.service
  path: /usr/local/bin/configure-unattended-upgrades
  permissions: '0755'

runcmd:
# Customize hostname (optional).
- sed -i -e 's/raspberrypi$/pihole/g' "/etc/hosts"

# Enable remote access using SSH
# Ref.: https://www.raspberrypi.com/documentation/computers/remote-access.html#ssh
- systemctl enable --now --no-block ssh

# Disable bluetooth and wifi (optional)
# TODO: Do not block wifi if you are using wifi instead of ethernet!
- rfkill block all
# or
#- rfkill block bluetooth

# Disable persistent logging in journald to reduce sd card wear and increase its lifespan (optional)
# Ref.: /usr/share/doc/systemd/README.Debian.gz
- rm -rf "/var/log/journal"
- systemctl restart systemd-journald.service

# Enable Docker Pi-hole
- systemctl enable --now --no-block pihole.service

# Configure unattended upgrades
# WARNING: Do not power off the Raspberry Pi while it is performing updates, which occur by default between 6am and 7am
# (cf. /lib/systemd/system/apt-daily-upgrade.timer). Interrupting the update process may result in a broken system. If
# unattended upgrades are not desired, comment out or remove the following line.
- configure-unattended-upgrades
EOF

cleanup
trap - INT EXIT

echo "Image has been written to: $pihole"
