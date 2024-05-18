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
* [`SD card` or `Micro SD card`](https://www.raspberrypi.org/documentation/installation/sd-cards.md)
  (depending on Raspberry Pi model) with a minimum size of `4GB`
* (Micro) SD card reader
* Running Operating System (Linux preferably) which is used to setup Pi-hole on the Raspberry Pi
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
card, e.g. using [`Raspberry Pi Imager`](https://www.raspberrypi.org/documentation/installation/). Finally, jump to the
[Router Setup](#router-setup) chapter.

First download and extract [`Raspberry Pi OS Lite`](https://www.raspberrypi.org/software/operating-systems/), then flash
it to the (Micro) SD card using e.g. [`Raspberry Pi Imager`](https://www.raspberrypi.org/documentation/installation/).
This guide was tested with `Raspberry Pi OS Lite` which was released on `March 15th 2024` and is based on Debian 12
(Bookworm).

Next step is to perform the network setup of Raspberry Pi. For an interactive setup (requires display and keyboard)
plug the SD card into the Raspberry Pi, power on the system and follow the official guides to configure a static (!)
ip address for [ethernet](https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-networking)
or [wifi](https://www.raspberrypi.com/documentation/computers/getting-started.html#wi-fi).

For a headless setup of the network, plug the SD card into the host OS, mount the second partition (`rootfs`) of the
SD card and edit the files for [ethernet](
https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-networking) or [wifi](
https://www.raspberrypi.com/documentation/computers/configuration.html#wireless-networking-command-line) directly.
For example, to set static IPv4 and IPv6 addresses for Raspberry Pi's ethernet port create a new file
`/etc/NetworkManager/system-connections/first.nmconnection`:
```
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
```

[Enable remote access using SSH](https://www.raspberrypi.com/documentation/computers/remote-access.html#ssh). For a
headless setup, plug the SD card into the host OS, mount the first partition (`boot`) of the SD card, `cd` into the
mounted directory and `touch ssh` (`sshswitch.service` will then enable SSH and remove this file on the next boot).

[Check for existing SSH keys](https://docs.github.com/en/github/authenticating-to-github/checking-for-existing-ssh-keys)
and [if you do not already have an SSH key then generate a new SSH key and add it to `ssh-agent`](
https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

Plug the SD card into the Raspberry Pi, power on the system and login with [SSH](
https://www.raspberrypi.com/documentation/computers/remote-access.html#ssh).
The default username is `pi` with password `raspberry`.

[Copy your SSH public key to the Raspberry Pi](
https://wiki.archlinux.org/index.php/SSH_Keys#Copying_the_public_key_to_the_remote_server).

The following steps will all be executed via SSH on the Raspberry Pi:

```sh
# Become root.
sudo -s

# Disable logins except ssh (optional).
passwd --lock pi

# Disable password authentication for SSH logins.
#
# NOTE: Ensure SSH public key authentication works before disable password authentication!
#
cat << 'EOF' > "/etc/ssh/sshd_config.d/99-disable-password-authentication.conf"
# 2024 Jakob Meng, <jakobmeng@web.de>
PasswordAuthentication no
EOF

# Restart ssh to apply changes.
systemctl restart ssh.service

# Disable bluetooth and wifi (optional)
# NOTE: Do not block wifi if you are using wifi instead of ethernet!
rfkill block all
# or
#rfkill block bluetooth

# Disable swap to reduce sd card wear and increase its lifespan (optional)
apt-get remove -y dphys-swapfile

# Disable persistent logging in journald to reduce sd card wear and increase its lifespan (optional)
# Ref.: /usr/share/doc/systemd/README.Debian.gz
rm -rf "/var/log/journal"

# Upgrade all installed packages
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# Install tools
apt-get install -y vim screen aptitude fzf git curl

# Install Docker runtime and Docker Compose
apt-get install -y docker.io docker-compose

# Change hostname using your favorite editor, e.g. Vim (optional)
vi /etc/hostname
vi /etc/hosts

# Reboot to apply changes
reboot
```

Login to Raspberry Pi via SSH after system has rebooted. Now we will enable unattended upgrades of `Raspberry Pi OS`.

:warning:
**NOTE:**
Do not power off your system while it is updating which will happen at 6am-7am by default (cf.
`/lib/systemd/system/apt-daily-upgrade.timer`). Interrupting the update process might cause a broken system!
If you do not want to enable unattended upgrades, skip the next paragraph.
:warning:

```sh
# Become root.
sudo -s

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

# Reboot to apply changes
reboot
```

Next we will setup [Pi-hole](https://pi-hole.net/) using
[Pi-hole's Docker image](https://github.com/pi-hole/docker-pi-hole/#running-pi-hole-docker).
[Docker Compose](https://docs.docker.com/compose/) will be used to manage the Docker containers.

Login to Raspberry Pi via SSH after system has rebooted. Create a config file `docker-compose.yml` in a new folder
`/opt/pihole` for Docker Compose:

```sh
# Become root.
sudo -s

# Prepare Docker Pi-hole.
mkdir -p "/opt/pihole"

# Create a new config Docker Compose using your favorite editor, e.g. Vim
vi "/opt/pihole/docker-compose.yml"
```

Docker Pi-hole provides an example config file for Docker Compose (without Watchtower) that could be used as a start
([`docker-compose.yml.example`](
https://github.com/pi-hole/docker-pi-hole/blob/master/examples/docker-compose.yml.example)).

The following `docker-compose.yml` example configures Docker Pi-hole with host networking mode to allow DHCP responses.
See [Docker DHCP and Network Modes](https://docs.pi-hole.net/docker/dhcp/) for rationale and other networking modes.
[Watchtower](https://containrrr.dev/watchtower/) will be used to automate base image updates of Pi-hole's Docker
container.

:warning:
**NOTE:**
Self-updating functionality triggered by Watchtower is experimental and might break Pi-hole! For example, updates to
the Docker image might require changes of the Docker Compose config, e.g. when deprecated variables have been removed.
If you do not want to enable updates using Watchtower, remove the `watchtower:` key and its content from the Docker
Compose file `docker-compose.yml`.
:warning:

```yaml
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
      #DHCP_ACTIVE: 'true'
      #DHCP_START:  '192.168.0.101' # first IPv4 address used for DHCP
      #DHCP_END:    '192.168.0.254' # last IPv4 address used for DHCP
      #DHCP_ROUTER: '192.168.0.1'   # router ip, mandatory if DHCP server is enabled
      #DHCP_LEASETIME: '64'

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
```

Now bring up all containers with:
```sh
# Become root.
sudo -s

cd "/opt/pihole"

# Run container in background.
docker-compose up -d

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

Open a browser and enter ip address of your Raspberry Pi. Navigate to the Pi-hole admin panel by following the link on
`Did you mean to go to the admin panel?`. Enter the web password and have a look around. Now proceed with router setup.

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
https://avm.de/service/fritzbox/fritzbox-7590/wissensdatenbank/publication/show/573) / [(EN)](
https://en.avm.de/service/fritzbox/fritzbox-7590/knowledge-base/publication/show/573).

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
