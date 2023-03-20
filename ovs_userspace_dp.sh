#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Connecting Docker containers with Open vSwitch bridges using the userspace datapath and a VXLAN tunnel
#
# Overview:
# Four Docker containers with different network namespaces are connected using veth devices, Open vSwitch bridges and
# a VXLAN tunnel. Both Open vSwitch services ovsdb-server and ovs-vswitchd are executed in containers. This provides a
# minimal and reproducible environment which minimizes interference with the host OS.
#
# Setup:
# * Container host is running Debian 11 (Bullseye)
# * Containers are named ctr0, ..., ctr3 and all have their own network namespace without connectivity to the host
# * Containers ctr1 and ctr2 will run Open vSwitch bridges using the userspace datapath
# * Containers ctr0 and ctr1 are connected via veth devices ctr0-high and ctr1-high
# * Containers ctr1 and ctr2 are connected via veth devices ctr1-low and ctr2-low
# * Containers ctr2 and ctr3 are connected via veth devices ctr2-high and ctr3-high
# * ctr1 and ctr2 each have two Open vSwitch bridges br-int and br-ext
# * ctr{0,1,2,3}-high have a MTU of 1450 bytes because traffic is tunneled via VXLAN
# * ctr{1,2}-high are connected to br-int
# * ctr{1,2}-low are connected to br-ext
# * br-ext on ctr1 has ip address 192.168.0.101/24
# * br-ext on ctr2 has ip address 192.168.0.102/24
# * ctr0-high on ctr0 has ip address 192.168.0.201/24
# * ctr3-high on ctr3 has ip address 192.168.0.202/24
# * both br-int bridges on ctr1 and ctr2 have a VXLAN port to connect br-int bridges on both containers
#   and thus establish connectivity between ctr0 and ctr3
#
# * Overview of network:
#
#   +------------------------------+               +------------------------------+
#   | 192.168.0.201/24 @ ctr0-high |               | 192.168.0.202/24 @ ctr3-high |
#   +------------------------------+               +------------------------------+
#      | (ctr0)                                       | (ctr3)
#      |                                              |
#      | (ctr1)                                       | (ctr2)
#   +----------------+                             +----------------+
#   | ctr1-high      |\                            | ctr2-high      |\
#   +----------------+ \                           +----------------+ \
#   | ctr2-vxlan0    |  { br-int }                 | ctr1-vxlan0    |  { br-int }
#   | remote:        | /                           | remote:        | /
#   |  192.168.0.102 |/                            |  192.168.0.101 |/
#   +----------------+                             +----------------+
#      |                                              |
#   +----------+                                   +----------+
#   | ctr1-low | { 192.168.0.101/24 @ br-ext }     | ctr2-low | { 192.168.0.102/24 @ br-ext }
#   +----------+                                   +----------+
#      | (ctr1)                                         | (ctr2)
#      \                                                |
#       -----------------------------------------------/

# On a bare-metal server with Debian 11 (Bullseye) open a shell and enter
sudo -s

# util-linux has nsenter
# iproute2 has ip
apt install -y iputils-ping iproute2 util-linux docker.io

# load kernel modules which are required for ovs-vswitchd
# also when launched in a container
modprobe openvswitch vxlan tun

exit # leave root shell

# build image with openvswitch installed because containers will not have internet connectivity

# python3-openvswitch is required for ovs-tcpdump
docker run -t --init --name build0 debian:bullseye \
    /bin/bash -c \
    'apt update && apt install -y openvswitch-switch python3-openvswitch vim iproute2 iputils-ping man-db tcpdump'
docker commit build0 openvswitch:local
docker rm build0

# ovs-vswitchd wants /dev/net/tun for VXLAN tunnel
# Ref.: https://mjmwired.net/kernel/Documentation/devices.txt

docker run -ti --init --detach --network none --cap-add NET_ADMIN --name ctr0 openvswitch:local /bin/bash

docker run -ti --init --detach --network none --cap-add NET_ADMIN --device /dev/net/tun --name ctr1 \
    openvswitch:local /bin/sh -c \
    '/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start && bash'

docker run -ti --init --detach --network none --cap-add NET_ADMIN --device /dev/net/tun --name ctr2 \
    openvswitch:local /bin/sh -c \
    '/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start && bash'

docker run -ti --init --detach --network none --cap-add NET_ADMIN --name ctr3 openvswitch:local /bin/bash

sudo -s

ctr_pid() { docker inspect --format '{{.State.Pid}}' "$1"; }
ip link add ctr1-low type veth peer name ctr2-low
ip link set ctr1-low netns "$(ctr_pid ctr1)"
ip link set ctr2-low netns "$(ctr_pid ctr2)"

ip link add ctr0-high mtu 1450 type veth peer name ctr1-high mtu 1450
ip link set ctr0-high netns "$(ctr_pid ctr0)"
ip link set ctr1-high netns "$(ctr_pid ctr1)"

ip link add ctr2-high mtu 1450 type veth peer name ctr3-high mtu 1450
ip link set ctr2-high netns "$(ctr_pid ctr2)"
ip link set ctr3-high netns "$(ctr_pid ctr3)"

exit # leave root shell

docker exec ctr1 ovs-vsctl --may-exist add-br br-int \
  -- set Bridge br-int datapath_type=netdev \
  -- br-set-external-id br-int bridge-id br-int \
  -- set bridge br-int fail-mode=standalone
docker exec ctr1 ovs-vsctl add-port br-int ctr1-high
docker exec ctr1 ovs-vsctl add-port br-int ctr2-vxlan0 \
  -- set interface ctr2-vxlan0 type=vxlan options:remote_ip=192.168.0.102

docker exec ctr2 ovs-vsctl --may-exist add-br br-int \
  -- set Bridge br-int datapath_type=netdev \
  -- br-set-external-id br-int bridge-id br-int \
  -- set bridge br-int fail-mode=standalone
docker exec ctr2 ovs-vsctl add-port br-int ctr2-high
docker exec ctr2 ovs-vsctl add-port br-int ctr1-vxlan0 \
  -- set interface ctr1-vxlan0 type=vxlan options:remote_ip=192.168.0.101

docker exec ctr1 ovs-vsctl --may-exist add-br br-ext \
    -- set Bridge br-ext datapath_type=netdev \
    -- br-set-external-id br-ext bridge-id br-ext \
    -- set bridge br-ext fail-mode=standalone
docker exec ctr1 ovs-vsctl --timeout 10 add-port br-ext ctr1-low

docker exec ctr2 ovs-vsctl --may-exist add-br br-ext \
    -- set Bridge br-ext datapath_type=netdev \
    -- br-set-external-id br-ext bridge-id br-ext \
    -- set bridge br-ext fail-mode=standalone
docker exec ctr2 ovs-vsctl --timeout 10 add-port br-ext ctr2-low

docker exec ctr1 ip link set ctr1-low up
docker exec ctr2 ip link set ctr2-low up
docker exec ctr1 ip link set ctr1-high up
docker exec ctr2 ip link set ctr2-high up

docker exec ctr1 ip addr add 192.168.0.101/24 dev br-ext
docker exec ctr2 ip addr add 192.168.0.102/24 dev br-ext
docker exec ctr1 ip link set br-ext up
docker exec ctr2 ip link set br-ext up

docker exec ctr1 ping -c 3 192.168.0.102
docker exec ctr2 ping -c 3 192.168.0.101

docker exec ctr0 ip link set ctr0-high up
docker exec ctr0 ip addr add 192.168.0.201/24 dev ctr0-high

docker exec ctr3 ip link set ctr3-high up
docker exec ctr3 ip addr add 192.168.0.202/24 dev ctr3-high

docker exec ctr0 ping -c 3 -M do -s 1422 192.168.0.202
docker exec ctr3 ping -c 3 -M do -s 1422 192.168.0.201

# set MTU larger than VXLAN payload size
docker exec ctr0 ip link set ctr0-high mtu 1500
docker exec ctr1 ip link set ctr1-high mtu 1500
docker exec ctr2 ip link set ctr2-high mtu 1500
docker exec ctr3 ip link set ctr3-high mtu 1500
# ping should fail with error message:
#  From 192.168.0.202 icmp_seq=2 Frag needed and DF set (mtu = 1450)
#  ping: local error: message too long, mtu=1450
docker exec ctr0 ping -c 3 -M do -s 1472 192.168.0.202
docker exec ctr3 ping -c 3 -M do -s 1472 192.168.0.201

docker kill ctr0 ctr1 ctr2 ctr3
docker rm ctr0 ctr1 ctr2 ctr3
docker rmi openvswitch:local
