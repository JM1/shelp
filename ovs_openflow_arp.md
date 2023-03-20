# Hands-on introduction to Open vSwitch and OpenFlow

This guide connects four Docker containers in different network namespaces with `veth` devices, Open vSwitch bridges and
a VXLAN tunnel using the kernel datapath. ARP responses are implemented with Open vSwitch flows and conventional address
resolution via the Linux kernel on the bridges is blocked. Open vSwitch services `ovsdb-server` and `ovs-vswitchd` are
executed in Docker containers. This allows to create a minimal and reproducible environment which minimizes interference
with the host OS.

**NOTE**: This guide assumes a understanding of [protocols used on OSI layers 2 to 4 (Data link, Network, Transport)
including ARP, IP, ICMP, TCP and UDP](https://en.wikipedia.org/wiki/Internet_protocol_suite). Further it assumes
experience with using Docker containers and Linux' [`veth` (Virtual Ethernet) interfaces](
https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking) and a basic
understanding of [container isolation using namespaces](https://en.wikipedia.org/wiki/Linux_namespaces). It also helps
to have used a OpenStack cloud or a OpenShift cloud before but this is not a must.

On a bare-metal server with Debian 11 (Bullseye) open a shell and enter:

```sh
# Connecting four Docker containers with Open vSwitch and a custom OpenFlow table
#
# Container overview:
#
#   +----------------------------------------------------------------------------+
#   |                                                                            |
#   | +------+      +------+      +------+      +------+                         |
#   | | ctr0 |@----@| ctr1 |@----@| ctr2 |@----@| ctr3 | ⬅️ 4x Docker containers |
#   | +------+      +------+      +------+      +------+                         |
#   |           ⬆️            ⬆️             ⬆️                                   |
#   |       veth pair      veth pair     veth pair                               |
#   +----------------------------------------------------------------------------+
#
# Network overview:
#
#        ➡️ +----------------------------+    +----------------------------+ ⬅️
#   ctr0 ➡️ | 192.168.0.1/24 @ ctr0-high |    | 192.168.0.2/24 @ ctr3-high | ⬅️ ctr3
#        ➡️ +----------------------------+    +----------------------------+ ⬅️
#              @                                 @
#              |                                 |
#              @                                 @
#        ➡️ +----------------+                +----------------+             ⬅️
#        ➡️ | ctr1-high      |\               | ctr2-high      |\            ⬅️
#        ➡️ +----------------+ \              +----------------+ \           ⬅️
#        ➡️ | ctr2-vxlan0    |  { br-int }    | ctr1-vxlan0    |  { br-int } ⬅️
#        ➡️ | remote:        | /              | remote:        | /           ⬅️
#   ctr1 ➡️ |  192.168.1.2   |/               |  192.168.1.1   |/            ⬅️ ctr2
#        ➡️ +----------------+                +----------------+             ⬅️
#        ➡️    |                                 |                           ⬅️
#        ➡️ +---------------------------+     +---------------------------+  ⬅️
#        ➡️ | 192.168.1.1/24 @ ctr1-low |@---@| 192.168.1.2/24 @ ctr2-low |  ⬅️
#        ➡️ +---------------------------+     +---------------------------+  ⬅️
#
# Details:
# * Container host is running Debian 11 (Bullseye)
# * Containers are named ctr0, ..., ctr3 and all have their own network namespace without
#   connectivity to the host
# * Containers ctr1 and ctr2 will run Open vSwitch bridges using the kernel datapath
# * Containers ctr0 and ctr1 are connected via veth devices ctr0-high and ctr1-high
# * Containers ctr1 and ctr2 are connected via veth devices ctr1-low and ctr2-low
# * Containers ctr2 and ctr3 are connected via veth devices ctr2-high and ctr3-high
# * ctr1 and ctr2 each have one Open vSwitch bridge br-int
# * ctr{0,1,2,3}-high have a MTU of 1450 bytes because traffic is tunneled via VXLAN
# * ctr{1,2}-high are connected to br-int
# * ctr1-low has ip address 192.168.1.1/24 and MAC address c0:de:b1:ee:d0:01
# * ctr2-low has ip address 192.168.1.2/24 and MAC address c0:de:b1:ee:d0:02
# * ctr0-high has ip address 192.168.0.1/24 and MAC address c0:de:b1:ee:d0:03
# * ctr1-high has MAC address c0:de:b1:ee:d0:04
# * ctr2-high has MAC address c0:de:b1:ee:d0:05
# * ctr3-high has ip address 192.168.0.2/24 and MAC address c0:de:b1:ee:d0:06
# * both br-int bridges on ctr1 and ctr2 have a VXLAN port to connect br-int bridges on
#   both containers and thus establish connectivity between ctr0 and ctr3
# * Bridge br-int on ctr1 will respond to ARP requests for 192.168.0.2 (ctr3-high)
#   from ctr0-high
# * Bridge br-int on ctr2 will respond to ARP requests for 192.168.0.1 (ctr0-high)
#   from ctr3-high
# * Any ARP traffic will be blocked across VXLAN tunnels
# * Open vSwitch's normal pipeline will not be used, by default any traffic will be dropped
# * ICMP traffic on both br-int bridges will be forwarded

sudo -s

# iproute2 has ip
apt install -y iputils-ping iproute2 docker.io

# load kernel modules which are required for ovs-vswitchd
# also when launched in a container
modprobe openvswitch vxlan tun

# build image with openvswitch installed because
# containers will not have internet connectivity

# python3-openvswitch is required for ovs-tcpdump
docker run -t --init --name build0 debian:bullseye /bin/bash -c \
'apt update && apt install -y openvswitch-switch'\
' python3-openvswitch vim iproute2 iputils-ping man-db tcpdump'
docker commit build0 openvswitch:local
docker rm build0

# ovs-vswitchd wants /dev/net/tun for VXLAN tunnel
# Ref.: https://mjmwired.net/kernel/Documentation/devices.txt

docker run -ti --init --detach --network none --cap-add NET_ADMIN \
    --name ctr0 openvswitch:local /bin/bash

docker run -ti --init --detach --network none --cap-add NET_ADMIN \
    --device /dev/net/tun --name ctr1 \
    openvswitch:local /bin/sh -c \
    '/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start && bash'

docker run -ti --init --detach --network none --cap-add NET_ADMIN \
    --device /dev/net/tun --name ctr2 \
    openvswitch:local /bin/sh -c \
    '/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start && bash'

docker run -ti --init --detach --network none --cap-add NET_ADMIN \
    --name ctr3 openvswitch:local /bin/bash

ctr_pid() { docker inspect --format '{{.State.Pid}}' "$1"; }
ip link add ctr1-low address c0:de:b1:ee:d0:01 type veth \
    peer name ctr2-low address c0:de:b1:ee:d0:02
ip link set ctr1-low netns "$(ctr_pid ctr1)"
ip link set ctr2-low netns "$(ctr_pid ctr2)"

ip link add ctr0-high address c0:de:b1:ee:d0:03 mtu 1450 type veth \
    peer name ctr1-high address c0:de:b1:ee:d0:04 mtu 1450
ip link set ctr0-high netns "$(ctr_pid ctr0)"
ip link set ctr1-high netns "$(ctr_pid ctr1)"

ip link add ctr2-high address c0:de:b1:ee:d0:05 mtu 1450 type veth \
    peer name ctr3-high address c0:de:b1:ee:d0:06 mtu 1450
ip link set ctr2-high netns "$(ctr_pid ctr2)"
ip link set ctr3-high netns "$(ctr_pid ctr3)"

docker exec ctr1 ovs-vsctl --may-exist add-br br-int \
  -- set Bridge br-int datapath_type=system \
  -- br-set-external-id br-int bridge-id br-int \
  -- set bridge br-int fail-mode=standalone
docker exec ctr1 ovs-vsctl add-port br-int ctr1-high
docker exec ctr1 ovs-vsctl add-port br-int ctr2-vxlan0 \
  -- set interface ctr2-vxlan0 type=vxlan options:remote_ip=192.168.1.2

docker exec ctr2 ovs-vsctl --may-exist add-br br-int \
  -- set Bridge br-int datapath_type=system \
  -- br-set-external-id br-int bridge-id br-int \
  -- set bridge br-int fail-mode=standalone
docker exec ctr2 ovs-vsctl add-port br-int ctr2-high
docker exec ctr2 ovs-vsctl add-port br-int ctr1-vxlan0 \
  -- set interface ctr1-vxlan0 type=vxlan options:remote_ip=192.168.1.1

docker exec ctr1 ip link set ctr1-high up
docker exec ctr2 ip link set ctr2-high up

docker exec ctr1 ip addr add 192.168.1.1/24 dev ctr1-low
docker exec ctr2 ip addr add 192.168.1.2/24 dev ctr2-low
docker exec ctr1 ip link set ctr1-low up
docker exec ctr2 ip link set ctr2-low up

docker exec ctr1 ping -c 3 192.168.1.2
docker exec ctr2 ping -c 3 192.168.1.1

docker exec ctr0 ip link set ctr0-high up
docker exec ctr0 ip addr add 192.168.0.1/24 dev ctr0-high

docker exec ctr3 ip link set ctr3-high up
docker exec ctr3 ip addr add 192.168.0.2/24 dev ctr3-high

# Q: When we ping from ctr0 to ctr3, what will happen on ctr0?
# Q: How can we monitor what is going on at ctr0-high?

docker exec ctr0 ping -c 3 -M do -s 1422 192.168.0.2
docker exec ctr3 ping -c 3 -M do -s 1422 192.168.0.1

docker exec ctr0 tcpdump -i any -en # in another tty
docker exec ctr3 tcpdump -i any -en # in another tty

docker exec ctr0 tcpdump -U -s 0 -w - -i ctr0-high | wireshark -k -i - # in another tty
docker exec ctr3 tcpdump -U -s 0 -w - -i ctr3-high | wireshark -k -i - # in another tty

docker exec ctr1 ovs-appctl ovs/route/show
docker exec ctr2 ovs-appctl ovs/route/show

# debug
docker exec ctr1 ovs-vsctl show
docker exec ctr1 ovs-ofctl show br-int
docker exec ctr1 ovs-ofctl dump-tables
docker exec ctr1 ovs-ofctl dump-flows br-int

# flush arp caches
docker exec ctr0 sh -c 'ip link set arp off dev ctr0-high; ip link set arp on dev ctr0-high'
docker exec ctr1 ovs-appctl fdb/flush br-int
docker exec ctr1 sh -c 'ip link set arp off dev ctr1-low; ip link set arp on dev ctr1-low'
docker exec ctr2 ovs-appctl fdb/flush br-int
docker exec ctr2 sh -c 'ip link set arp off dev ctr2-low; ip link set arp on dev ctr2-low'
docker exec ctr3 sh -c 'ip link set arp off dev ctr3-high; ip link set arp on dev ctr3-high'

# drop any ARP traffic for VXLAN tunnel
docker exec ctr1 ovs-ofctl add-flow br-int 'table=0, priority=1, arp, actions=drop'
docker exec ctr2 ovs-ofctl add-flow br-int 'table=0, priority=1, arp, actions=drop'

# ping fails because address resolution for 192.168.0.2 failed
docker exec ctr0 ping -c 3 -M do -s 1422 192.168.0.2

# bridges will answer ARP requests for 192.168.0.1 and 192.168.0.2
docker exec ctr1 ovs-ofctl add-flow br-int 'table=0, priority=2, arp, arp_op=1, arp_tpa=192.168.0.2 actions=load:2->arp_op,move:arp_sha->arp_tha,push:arp_tpa,move:arp_spa->arp_tpa,pop:arp_spa,load:0xc0deb1eed006->arp_sha,move:arp_sha->eth_src,move:arp_tha->eth_dst,output:in_port'
docker exec ctr2 ovs-ofctl add-flow br-int 'table=0, priority=2, arp, arp_op=1, arp_tpa=192.168.0.1 actions=load:2->arp_op,move:arp_sha->arp_tha,push:arp_tpa,move:arp_spa->arp_tpa,pop:arp_spa,load:0xc0deb1eed003->arp_sha,move:arp_sha->eth_src,move:arp_tha->eth_dst,output:in_port'

docker exec ctr0 ping -c 3 -M do -s 1422 192.168.0.2
docker exec ctr3 ping -c 3 -M do -s 1422 192.168.0.1

# drop traffic by default instead of using Open vSwitch's normal pipeline
docker exec ctr1 ovs-ofctl mod-flows --strict br-int 'table=0, priority=0, actions=drop'
docker exec ctr2 ovs-ofctl mod-flows --strict br-int 'table=0, priority=0, actions=drop'

# ping fails because icmp traffic gets blocked
docker exec ctr0 ping -c 3 -M do -s 1422 192.168.0.2

# forward icmp traffic
docker exec ctr1 ovs-ofctl add-flow br-int 'table=0, priority=1, icmp, in_port:ctr1-high, actions=output:ctr2-vxlan0'
docker exec ctr1 ovs-ofctl add-flow br-int 'table=0, priority=1, icmp, in_port:ctr2-vxlan0, actions=output:ctr1-high'
docker exec ctr2 ovs-ofctl add-flow br-int 'table=0, priority=1, icmp, in_port:ctr2-high, actions=output:ctr1-vxlan0'
docker exec ctr2 ovs-ofctl add-flow br-int 'table=0, priority=1, icmp, in_port:ctr1-vxlan0, actions=output:ctr2-high'

docker exec ctr0 ping -c 3 -M do -s 1422 192.168.0.2
docker exec ctr3 ping -c 3 -M do -s 1422 192.168.0.1

# debug
docker exec ctr1 ovs-ofctl dump-flows br-int
docker exec ctr2 ovs-ofctl dump-flows br-int

# trace icmp request from 192.168.0.1 to 192.168.0.2
docker exec ctr1 ovs-appctl ofproto/trace br-int \
    in_port=ctr1-high,eth_src=c0:de:b1:ee:d0:03,eth_dst=c0:de:b1:ee:d0:06,icmp,ip_src=192.168.0.1,ip_dst=192.168.0.2,icmp_type=8,icmp_code=0

# trace icmp reply from 192.168.0.2 to 192.168.0.1
docker exec ctr1 ovs-appctl ofproto/trace br-int \
    in_port=ctr1-low,eth_src=c0:de:b1:ee:d0:06,eth_dst=c0:de:b1:ee:d0:03,icmp,ip_src=192.168.0.2,ip_dst=192.168.0.1,icmp_type=0,icmp_code=0

docker kill ctr0 ctr1 ctr2 ctr3
docker rm ctr0 ctr1 ctr2 ctr3
docker rmi openvswitch:local
```
