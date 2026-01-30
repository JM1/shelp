[//]: # ( vim:set syntax=markdown fileformat=unix shiftwidth=4 softtabstop=4 expandtab textwidth=120: )
[//]: # ( kate: syntax markdown; end-of-line unix; space-indent on; indent-width 4; word-wrap-column 120; )
[//]: # ( kate: word-wrap on; remove-trailing-spaces modified; )

# Guide for self-updating Pi-hole setup on Raspberry Pi with IPv4 and IPv6

## Prerequisites

What you need:
* [`Raspberry Pi`](https://www.raspberrypi.org/products/) which will host Pi-hole later:
  + `Raspberry Pi 1 Model B`
  + `Raspberry Pi 1 Model B+`
  + `Raspberry Pi 2 Model B`
  + `Raspberry Pi 3 Model A+` (no ethernet, only wifi)
  + `Raspberry Pi 3 Model B`
  + `Raspberry Pi 3 Model B+`
  + `Raspberry Pi 4 Model B`
  + `Raspberry Pi 400`
  + `Raspberry Pi 5`
* [High-quality power supply](https://www.raspberrypi.org/products/)
* [`SD card` or `Micro SD card`](https://www.raspberrypi.com/documentation/accessories/sd-cards.html)
  (depending on Raspberry Pi model) with a minimum size of `4GB`
* (Micro) SD card reader
* Running Operating System (Linux preferably) which is used to set up Pi-hole on the Raspberry Pi
* Ethernet cable (optional) because this guide presumes a wired connection to setup and operate Pi-hole
* Access to router on local network with permission to change DHCP settings

No display or keyboard has to be attached to the Raspberry Pi because this guide performs a headless installation.
But attaching both is still useful for diagnosing problems.

Other Raspberry Pi's, such as `Raspberry Pi Zero`, might also be compatible to Docker Pi-hole, but are likely to require
extra configuration steps due to missing ethernet or wifi interfaces.

One single core systems, such as `Raspberry Pi Zero`, `Raspberry Pi 1 Model B` and `Raspberry Pi 1 Model B+`,
performance might be better on native Pi-hole installs, without Docker's multi-tasking.

## Raspberry Pi Setup

**NOTE:** Script [rpi_pi-hole_assembler.sh](rpi_pi-hole_assembler.sh) automates most of steps in this chapter: It
downloads and prepares a Raspberry PI OS image with Docker Pi-hole. Simply edit the script in your favorite editor and
customize all configuration settings marked with `TODO`. Afterwards run it and flash the resulting image to a (Micro) SD
card, e.g. using [`Raspberry Pi Imager`](
https://www.raspberrypi.com/documentation/computers/getting-started.html#raspberry-pi-imager). Finally, jump to the
[Router Setup](#router-setup) chapter.

First download and extract [`Raspberry Pi OS Lite`](https://www.raspberrypi.org/software/operating-systems/), then flash
it to the (Micro) SD card using e.g. [`Raspberry Pi Imager`](
https://www.raspberrypi.com/documentation/computers/getting-started.html#raspberry-pi-imager). This guide was tested
with `Raspberry Pi OS Lite` which was released on `December 4th 2025` and is based on Debian 13 (Trixie). Do **not**
insert the SD card into the Raspberry Pi yet.

[Check for existing SSH keys](https://docs.github.com/en/github/authenticating-to-github/checking-for-existing-ssh-keys)
and [if you do not already have an SSH key then generate a new SSH key and add it to `ssh-agent`](
https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

Next, mount the second partition (`rootfs`) of the SD card. Follow the instructions below to apply a workaround for a
[known Raspberry Pi OS issue in which cloud-init does not wait for clock synchronization before executing its final
stage, which may include package updates](https://github.com/RPi-Distro/rpi-cloud-init-mods/issues/3):

```sh
# NOTE: Adjust this path to match the mount directory of the second partition (rootfs) on the SD card
rootmnt="/media/$USER/rootfs"

# HACK: Wait for clock synchronization before running the final cloud-init stage, which may run package updates.
# Ref.: https://github.com/RPi-Distro/rpi-cloud-init-mods/issues/3
sudo mkdir -p "$rootmnt/etc/systemd/system/sysinit.target.wants"
sudo ln -s "/usr/lib/systemd/system/systemd-time-wait-sync.service" \
  "$rootmnt/etc/systemd/system/sysinit.target.wants/systemd-time-wait-sync.service"
```

Then use a partition editor such as [GParted](https://gparted.org) to change the filesystem label of the first
partition of the SD card from `bootfs` to `cidata` ([instructions](
https://gparted.org/display-doc.php?name=help-manual#gparted-setting-partition-file-system-label)). This is a
workaround for another [known Raspberry Pi OS issue in which cloud-init cannot locate nor mount the NoCloud datasource](
https://github.com/RPi-Distro/rpi-cloud-init-mods/issues/2).

Afterwards, mount the `cidata` partition and find the cloud-init configuration files `network-config` and `user-data`.
Editing file `network-config` is optional, it is used for headless network configuration ([network-config v2 reference](
https://cloudinit.readthedocs.io/en/latest/reference/network-config-format-v2.html)). For example, the following
`network-config` sets static IPv4 and IPv6 addresses for Raspberry Pi's Ethernet port:

```yaml
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
```

Network configuration of the Raspberry Pi can also be performed interactively later (requires display and keyboard).
Follow the official documentation to configure a static (!) ip address for
[Ethernet](https://www.raspberrypi.com/documentation/computers/configuration.html#networking)
or [Wifi](https://www.raspberrypi.com/documentation/computers/getting-started.html#wi-fi).

Raspberry Pi OS is configured using the `user-data` file, which contains the cloud-init configuration aka cloud config.
cloud-init reads `user-data` during first boot to provision SSH keys, packages, and other components (see
[introduction](https://cloudinit.readthedocs.io/en/latest/explanation/introduction.html)).

The cloud config below will:
* Configure unattended upgrades.
* Set up [Pi-hole](https://pi-hole.net/) using [Pi-hole's Docker image](
  https://github.com/pi-hole/docker-pi-hole/#running-pi-hole-docker).
* Install [Docker Compose](https://docs.docker.com/compose/) to manage the Docker Pi-hole container.
* Enable [Watchtower](https://containrrr.dev/watchtower/) to automate base image updates for the Pi-hole Docker
  container.

Refer to the [cloud-init module reference](https://cloudinit.readthedocs.io/en/latest/reference/modules.html)
for explanations of each option.

Please customize all configuration settings marked with `TODO` in the cloud config below and take note of the
`WARNING`s and `NOTE`s. Then overwrite the existing `user-data` file on the `cidata` partition of the SD card with the
modified content.

```yaml
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
```

Unmount both SD card partitions, `cidata` (fka `bootfs`) and `rootfs`. Insert the SD card into the Raspberry Pi and
power it on. The cloud-init provisioning may take up to an hour to complete. Afterwards, login with [SSH](
https://www.raspberrypi.com/documentation/computers/remote-access.html#ssh). The default username is `pi` with password
`raspberry`. Perform the following steps via SSH on the Raspberry Pi to verify system healthy:

```sh
# Become root.
sudo -s

cd "/opt/pihole"

# Verify that all containers are up and running.
docker ps

# View output of Pi-hole container.
docker logs pihole

# Get web password.
# NOTE: Keep a backup of the web password because only the printed random password of the first run will be used
#       and stored as web password within Pi-hole. On later runs the random passwords will be ignored.
#       Ref.: https://github.com/pi-hole/docker-pi-hole/issues/781#issuecomment-775241580
docker logs pihole | grep -i password
```

Open a browser and enter the Raspberry PI's IP address. Navigate to the Pi-hole admin panel using the link behind
`Did you mean to go to your Pi-hole's dashboard instead?`. Enter the web password to access the dashboard, explore
the interface, and then proceed with the router configuration.

## Router Setup

### AVM FRITZ!Box

Follow [Pi-hole's official guide to setup your fritzbox](https://docs.pi-hole.net/routers/fritzbox/) so that it
distributes Pi-hole as DNS server for IPv4 via DHCP.

In short, first enable `Advanced` (`Erweitert` in german) view on fritzbox's web interface by clicking on `Standard`
in the lower left corner on the welcome screen. Then enter Pi-hole's IPv4 address as `Local DNS server` at `Home
Network` :arrow_right: `Network` :arrow_right: `Network Settings` :arrow_right: `IP Adresses` :arrow_right: `IPv4
Configuration` :arrow_right: `Home Network`. On a german user interface this option `Lokaler DNS-Server` can be found at
`Heimnetz` :arrow_right: `Netzwerk` :arrow_right: `Netzwerkeinstellungen` :arrow_right:`IP-Adressen` :arrow_right:
`IPv4-Konfiguration` :arrow_right: `Heimnetz`.

To enable Pi-hole for IPv4 clients of the guest network you will have to setup Pi-hole as the upstream DNSv4 server of
your fritzbox. Navigate to `Internet` :arrow_right: `Account Information` :arrow_right: `DNS server` and enter Pi-hole's
IPv4 address as `Preferred DNSv4 server` and `Alternative DNSv4 server`. On a german ui this options can be found as
`Bevorzugter DNSv4-Server` and `Alternativer DNSv4-Server` at `Internet` :arrow_right: `Zugangsdaten` :arrow_right:
`DNS-Server`.

At the time of writing Pi-hole's fritzbox guide does not cover the IPv6 setup. First ensure that IPv6 support has been
configured on your fritzbox, e.g. follow the official AVM guides for IPv6 on FRITZ!Box 7590 [(DE)](
https://avm.de/service/wissensdatenbank/dok/FRITZ-Box-7590/573_IPv6-in-FRITZ-Box-einrichten/) / [(EN)](
https://en.avm.de/service/knowledge-base/dok/FRITZ-Box-7590/573_Configuring-IPv6-in-the-FRITZ-Box/).

Then navigate to `Home Network` :arrow_right: `Network` :arrow_right: `Network Settings` :arrow_right: `IP Adresses`
:arrow_right: `IPv6 Configuration` :arrow_right: ` Unique Local Addresses`. Tick/enable option `Always assign unique
local addresses (ULA)`. Here you will also find the Unique Local Address (ULA) of your fritzbox. Ensure that the first
64 bits of the Raspberry Pi's IPv6 ULA (`fd00:0000:0000:0000` in `/etc/dhcpcd.conf` example above) do match your
fritzbox's ULA. Scroll down to header `DNSv6 Server in the Home Network`, tick/enable `Also announce DNSv6 server via
router advertisement (RFC 5006)` and enter the IPv6 address of your Raspberry Pi as the announced DNSv6 server.
On german fritzboxes the menu can be found at `Heimnetz` :arrow_right: `Netzwerk` :arrow_right: `Netzwerkeinstellungen`
:arrow_right:`IP-Adressen` :arrow_right: `IPv6-Konfiguration`. Tick `Unique Local Addresses (ULA) immer zuweisen` and
`DNSv6-Server auch über Router Advertisement bekanntgeben (RFC 5006)`. Then enter Pi-hole's IPv6 address in `Lokaler
DNSv6-Server`.

To enable Pi-hole for IPv6 clients of the guest network you will have to setup Pi-hole as the upstream DNSv6 server of
your fritzbox. The steps for IPv6 are equal to the IPv4 setup above except that the IPv6 options are named `Preferred
DNSv6 server` and `Alternative DNSv6 server` or in german `Bevorzugter DNSv4-Server` and `Alternativer DNSv4-Server`.

### Others

Configure your router to announce Pi-hole's IPv4 and IPv6 addresses as DNS servers on your local network, the necessary
steps should be roughly equivalent to the AVM FRITZ!Box setup described above.

If your router does not allow to change the DNS server that its DHCP server announces then try to disable your
router's DHCP server completely and enable Pi-hole's DHCP server instead.

If your router does not allow to change the DNS server and to disable the DHCP server, then manually set the DNS servers
of your devices to the IPv4 and IPv6 addresses of your Raspberry Pi.

For help you might have a look at Pi-hole's [`Discourse User Forum`](https://discourse.pi-hole.net/) and
[FAQ](https://discourse.pi-hole.net/c/faqs).

## Test

Take any device that is on your local network like e.g. smartphone. Disconnect it from network and (re)connect it to
your network. Check which DNS name servers have been assigned to your device, e.g. [follow this guide to find your
DNS](https://smallbusiness.chron.com/primary-secondary-dns-65413.html). It should list the ip address(es) of Pi-hole.

Navigate to adblocker test pages ([example](https://canyoublockit.com/testing/), another
[example](https://fuzzthepiguy.tech/adtest/)) to see if Pi-hole does its job for IPv4 pages.

Test IPv6 connectivity with [`test-ipv6.com`](https://test-ipv6.com/).

Test if Pi-hole is used as a IPv6 DNS resolver. For example, use `dig` which is provided by distribution packages that
might be named [`bind-tools`](https://pkgs.org/search/?q=bind-tools),
[`bind-utils`](https://pkgs.org/search/?q=bind-utils) or [`dnsutils`](https://pkgs.org/search/?q=dnsutils):

```sh
# Map domain name to IPv6 address
# SERVER should be the IPv6 address of Pi-hole
dig AAAA heise.de -6
```

On an Apple iPhone or iPad install iSH ([github](https://github.com/ish-app/ish),
[ios](https://apps.apple.com/us/app/ish-shell/id1436902243)), reconnect to your Wifi and enter in iSH:

```sh
# install dig
akg add bind-tools

# Map domain name to IPv6 address
# SERVER should be the IPv6 address of Pi-hole
dig AAAA heise.de -6
```

## License

[Creative Commons Attribution Share Alike 4.0 International
(`CC-BY-SA-4.0`)](https://creativecommons.org/licenses/by-sa/4.0/)

## Author

Jakob Meng
@jm1 ([github](https://github.com/jm1), [galaxy](https://galaxy.ansible.com/jm1), [web](http://www.jakobmeng.de))
