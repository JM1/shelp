# Introducing Open vSwitch's `learn` action for adding or modifying OpenFlow tables

This guide implements local ARP responders and ICMP responders in Open vSwitch. It builds upon the preceding guide
[`ovs_openflow_arp.md`](ovs_openflow_arp.md) and introduces Open vSwitch's `learn` action. The latter allows to add and
modify flows in OpenFlow tables.

**NOTE**: This guide assumes a understanding of [protocols used on OSI layers 2 to 4 (Data link, Network, Transport)
including ARP, IP, ICMP, TCP and UDP](https://en.wikipedia.org/wiki/Internet_protocol_suite). Further it assumes
experience with using Docker containers and Linux' [`veth` (Virtual Ethernet) interfaces](
https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking) and a basic
understanding of [container isolation using namespaces](https://en.wikipedia.org/wiki/Linux_namespaces). It also helps
to have used a OpenStack cloud or a OpenShift cloud before but this is not a must.

On a bare-metal server with Debian 11 (Bullseye) open a shell and enter:

```sh
# Connecting four Docker containers with Open vSwitch, its flow pipeline and local ARP and ICMP responders
#
# Setup:
# * Container host is running Debian 11 (Bullseye)
# * Containers are named ctr0, ..., ctr3 and all have their own network namespace without connectivity to the host
# * Containers ctr1 and ctr2 will run Open vSwitch bridges using the kernel datapath
# * Containers ctr0 and ctr1 are connected via veth devices ctr0-high and ctr1-high
# * Containers ctr1 and ctr2 are connected via veth devices ctr1-low and ctr2-low
# * Containers ctr2 and ctr3 are connected via veth devices ctr2-high and ctr3-high
# * ctr1 and ctr2 each have one Open vSwitch bridge br-int
# * ctr{1,2}-{high,low} are connected to br-int
# * ctr1-low has MAC address c0:de:b1:ee:d0:01
# * ctr2-low has MAC address c0:de:b1:ee:d0:02
# * ctr0-high has ip address 192.168.0.201/24 and MAC address c0:de:b1:ee:d0:03
# * ctr1-high has MAC address c0:de:b1:ee:d0:04
# * ctr2-high has MAC address c0:de:b1:ee:d0:05
# * ctr3-high has ip address 192.168.0.202/24 and MAC address c0:de:b1:ee:d0:06
# * Bridge br-int on ctr1 will respond to ARP requests for 192.168.0.202 (ctr3-high) from ctr0-high
# * Bridge br-int on ctr2 will respond to ARP requests for 192.168.0.201 (ctr0-high) from ctr3-high
# * Any ARP traffic will be blocked across ctr{1,2}-low devices
# * Open vSwitch's normal pipeline will not be used, by default any traffic will be dropped
# * ICMP traffic on both br-int bridges will be forwarded and learned
# * Subsequent ICMP requests will be answered by bridges br-int for 60 seconds
#
# * Overview of network:
#
#   +------------------------------+    +------------------------------+
#   | 192.168.0.201/24 @ ctr0-high |    | 192.168.0.202/24 @ ctr3-high |
#   +------------------------------+    +------------------------------+
#      | (ctr0)                            | (ctr3)
#      |                                   |
#      | (ctr1)                            | (ctr2)
#   +----------------+                  +----------------+
#   | ctr1-high      |\                 | ctr2-high      |\
#   +----------------+ { br-int }       +----------------+ { br-int }
#   | ctr1-low       |/                 | ctr2-low       |/
#   +----------------+                  +----------------+
#       \ (ctr1)                           / (ctr2)
#        ----------------------------------

sudo -s

# util-linux has nsenter
# iproute2 has ip
apt install -y iputils-ping iproute2 util-linux docker.io

# load kernel modules which are required for ovs-vswitchd
# also when launched in a container
modprobe openvswitch

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

docker run -ti --init --detach --network none --cap-add NET_ADMIN --name ctr1 \
    openvswitch:local /bin/sh -c \
    '/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start && bash'

docker run -ti --init --detach --network none --cap-add NET_ADMIN --name ctr2 \
    openvswitch:local /bin/sh -c \
    '/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start && bash'

docker run -ti --init --detach --network none --cap-add NET_ADMIN --name ctr3 openvswitch:local /bin/bash

ctr_pid() { docker inspect --format '{{.State.Pid}}' "$1"; }
ip link add ctr1-low address c0:de:b1:ee:d0:01 type veth peer name ctr2-low address c0:de:b1:ee:d0:02
ip link set ctr1-low netns "$(ctr_pid ctr1)"
ip link set ctr2-low netns "$(ctr_pid ctr2)"

ip link add ctr0-high address c0:de:b1:ee:d0:03 type veth peer name ctr1-high address c0:de:b1:ee:d0:04
ip link set ctr0-high netns "$(ctr_pid ctr0)"
ip link set ctr1-high netns "$(ctr_pid ctr1)"

ip link add ctr2-high address c0:de:b1:ee:d0:05 type veth peer name ctr3-high address c0:de:b1:ee:d0:06
ip link set ctr2-high netns "$(ctr_pid ctr2)"
ip link set ctr3-high netns "$(ctr_pid ctr3)"

docker exec ctr1 ovs-vsctl --may-exist add-br br-int \
  -- set Bridge br-int datapath_type=system \
  -- br-set-external-id br-int bridge-id br-int \
  -- set bridge br-int fail-mode=standalone
docker exec ctr1 ovs-vsctl add-port br-int ctr1-high
docker exec ctr1 ovs-vsctl add-port br-int ctr1-low

docker exec ctr2 ovs-vsctl --may-exist add-br br-int \
  -- set Bridge br-int datapath_type=system \
  -- br-set-external-id br-int bridge-id br-int \
  -- set bridge br-int fail-mode=standalone
docker exec ctr2 ovs-vsctl add-port br-int ctr2-high
docker exec ctr2 ovs-vsctl add-port br-int ctr2-low

docker exec ctr1 ip link set ctr1-high up
docker exec ctr2 ip link set ctr2-high up
docker exec ctr1 ip link set ctr1-low up
docker exec ctr2 ip link set ctr2-low up

docker exec ctr0 ip link set ctr0-high up
docker exec ctr0 ip addr add 192.168.0.201/24 dev ctr0-high

docker exec ctr3 ip link set ctr3-high up
docker exec ctr3 ip addr add 192.168.0.202/24 dev ctr3-high

docker exec ctr0 ping -c 3 -M do -s 1422 192.168.0.202
docker exec ctr3 ping -c 3 -M do -s 1422 192.168.0.201

# flush arp caches
docker exec ctr0 sh -c 'ip link set arp off dev ctr0-high; ip link set arp on dev ctr0-high'
docker exec ctr1 ovs-appctl fdb/flush br-int
docker exec ctr1 sh -c 'ip link set arp off dev ctr1-low; ip link set arp on dev ctr1-low'
docker exec ctr2 ovs-appctl fdb/flush br-int
docker exec ctr2 sh -c 'ip link set arp off dev ctr2-low; ip link set arp on dev ctr2-low'
docker exec ctr3 sh -c 'ip link set arp off dev ctr3-high; ip link set arp on dev ctr3-high'

# debug
docker exec ctr1 ovs-vsctl show
docker exec ctr1 ovs-ofctl show br-int
docker exec ctr1 ovs-ofctl dump-tables
docker exec ctr1 ovs-ofctl dump-flows br-int

docker exec -i ctr1 ovs-ofctl -O OpenFlow12 replace-flows br-int - << 'EOF'
# drop any ARP traffic
table=0, priority=1, arp, actions=drop
# bridges will answer ARP requests for 192.168.0.201 and 192.168.0.202
table=0, priority=2, arp, arp_op=1, arp_tpa=192.168.0.202 actions=load:2->arp_op,move:arp_sha->arp_tha,push:arp_tpa,move:arp_spa->arp_tpa,pop:arp_spa,load:0xc0deb1eed006->arp_sha,move:arp_sha->eth_src,move:arp_tha->eth_dst,output:in_port
# learn icmp replies for 60 seconds
table=0, priority=3, in_port=ctr1-low, icmp, icmp_type=0, icmp_code=0, actions=learn(table=99, eth_type=0x0800, ip_dst=ip_src, ip_src=ip_dst, load:0x1337->reg0, hard_timeout=60), output:ctr1-high
# try to use learned icmp data to respond to icmp requests
# icmp echo and reply messages have a checksum field which we do not update here but luckily ping will ignore it
# Ref.: https://www.rfc-editor.org/rfc/rfc792
table=0, priority=3, in_port=ctr1-high, icmp, icmp_type=8, icmp_code=0, actions=resubmit(,99), resubmit(,1)
table=1, reg0=0, actions=output:ctr1-low
table=1, icmp, reg0=0x1337, actions=load:0->icmp_type,push:ip_dst,move:ip_src->ip_dst,pop:ip_src,push:eth_dst,move:eth_src->eth_dst,pop:eth_src,output:in_port
# forward icmp traffic
table=0, priority=1, icmp, in_port:ctr1-high, actions=output:ctr1-low
table=0, priority=1, icmp, in_port:ctr1-low, actions=output:ctr1-high
# drop traffic by default instead of using Open vSwitch's normal pipeline
table=0, priority=0, actions=drop
EOF

docker exec -i ctr2 ovs-ofctl -O OpenFlow12 replace-flows br-int - << 'EOF'
# drop any ARP traffic
table=0, priority=1, arp, actions=drop
# bridges will answer ARP requests for 192.168.0.201 and 192.168.0.202
table=0, priority=2, arp, arp_op=1, arp_tpa=192.168.0.201 actions=load:2->arp_op,move:arp_sha->arp_tha,push:arp_tpa,move:arp_spa->arp_tpa,pop:arp_spa,load:0xc0deb1eed003->arp_sha,move:arp_sha->eth_src,move:arp_tha->eth_dst,output:in_port
# learn icmp replies for 60 seconds
table=0, priority=3, in_port=ctr2-low, icmp, icmp_type=0, icmp_code=0, actions=learn(table=99, eth_type=0x0800, ip_dst=ip_src, ip_src=ip_dst, load:0x1337->reg0, hard_timeout=60), output:ctr2-high
# try to use learned icmp data to respond to icmp requests
# icmp echo and reply messages have a checksum field which we do not update here but luckily ping will ignore it
# Ref.: https://www.rfc-editor.org/rfc/rfc792
table=0, priority=3, in_port=ctr2-high, icmp, icmp_type=8, icmp_code=0, actions=resubmit(,99), resubmit(,1)
table=1, reg0=0, actions=output:ctr2-low
table=1, icmp, reg0=0x1337, actions=load:0->icmp_type,push:ip_dst,move:ip_src->ip_dst,pop:ip_src,push:eth_dst,move:eth_src->eth_dst,pop:eth_src,output:in_port
# forward icmp traffic
table=0, priority=1, icmp, in_port:ctr2-high, actions=output:ctr2-low
table=0, priority=1, icmp, in_port:ctr2-low, actions=output:ctr2-high
# drop traffic by default instead of using Open vSwitch's normal pipeline
table=0, priority=0, actions=drop
EOF

# debug
docker exec ctr1 ovs-ofctl dump-flows br-int
docker exec ctr2 ovs-ofctl dump-flows br-int
docker exec ctr0 tcpdump -U -s 0 -w - -i ctr0-high | wireshark -k -i -
docker exec ctr3 tcpdump -U -s 0 -w - -i ctr3-high | wireshark -k -i -

docker exec ctr0 ping -c 99 -M do -s 1422 192.168.0.202
# only a single icmp request from ctr0 will hit ctr3 every 60 seconds
docker exec -t ctr0 tcpdump -i any -en # in another tty
docker exec -t ctr3 tcpdump -i any -en # in another tty

# clear learned ips
docker exec ctr1 ovs-ofctl del-flows br-int table=99
docker exec ctr2 ovs-ofctl del-flows br-int table=99

# trace icmp request from 192.168.0.201 to 192.168.0.202
docker exec ctr1 ovs-appctl ofproto/trace br-int \
    in_port=ctr1-high,eth_src=c0:de:b1:ee:d0:03,eth_dst=c0:de:b1:ee:d0:06,icmp,ip_src=192.168.0.201,ip_dst=192.168.0.202,icmp_type=8,icmp_code=0

# trace (and learn) icmp reply from 192.168.0.202 to 192.168.0.201
docker exec ctr1 ovs-appctl ofproto/trace br-int \
    in_port=ctr1-low,eth_src=c0:de:b1:ee:d0:06,eth_dst=c0:de:b1:ee:d0:03,icmp,ip_src=192.168.0.202,ip_dst=192.168.0.201,icmp_type=0,icmp_code=0 -generate

# trace icmp request from 192.168.0.201 to 192.168.0.202 using learned data
docker exec ctr1 ovs-appctl ofproto/trace br-int \
    in_port=ctr1-high,eth_src=c0:de:b1:ee:d0:03,eth_dst=c0:de:b1:ee:d0:06,icmp,ip_src=192.168.0.201,ip_dst=192.168.0.202,icmp_type=8,icmp_code=0

docker kill ctr0 ctr1 ctr2 ctr3
docker rm ctr0 ctr1 ctr2 ctr3
docker rmi openvswitch:local
```
