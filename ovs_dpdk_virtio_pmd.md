# Creating a Open vSwitch bridge with DPDK and `virtio-pmd` in a QEMU/KVM VM

This guide shows how to create a [Open vSwitch bridge with DPDK](
https://docs.openvswitch.org/en/latest/howto/dpdk/) and [the `virtio-pmd` driver](
https://doc.dpdk.org/guides/nics/virtio.html) in a QEMU/KVM based virtual machine.

On a bare-metal server with Debian 11 (Bullseye) open a shell and enter:

```sh
sudo -s

# iproute2 has ip
# gdisk has sgdisk
# qemu-utils has qemu-img and qemu-nbd
apt install -y iputils-ping iproute2 docker.io wget gdisk kpartx qemu-utils

# load kernel modules which are required for ovs-vswitchd
# also when launched in a container and for qemu-nbd
modprobe openvswitch vfio nbd

# Allocate huge pages and mount them at /dev/hugepages
# Ref.:
# https://docs.openvswitch.org/en/latest/intro/install/dpdk/
# https://www.kernel.org/doc/html/latest/admin-guide/mm/hugetlbpage.html
mountpoint /dev/hugepages

exit # leave root shell

# Debian 12 (Bookworm) is required to get a fix [1] for QEMU.
# [1] https://gitlab.com/qemu-project/qemu/-/commit/f6ab64c05f8a6229bf6

# python3-openvswitch is required for ovs-tcpdump
docker run -t --init --name build1 debian:bookworm \
    /bin/bash -c \
    'apt-get update && apt-get install -y openssh-client openvswitch-switch-dpdk python3-openvswitch vim iproute2 iputils-ping man-db tcpdump qemu-kvm qemu-system-gui-'
docker commit build1 ovs-dpdk:local
docker rm build1

mkdir /tmp/data
cd /tmp/data

# prepare disk image for virtual machine
wget https://cdimage.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2 -O debian.qcow2
qemu-img resize debian.qcow2 16G
qemu-nbd --connect=/dev/nbd0 debian.qcow2
kpartx /dev/nbd0
sgdisk --print /dev/nbd0
# Disk /dev/nbd0: 4194304 sectors, 2.0 GiB
# Sector size (logical/physical): 512/512 bytes
# Disk identifier (GUID): 367C4A27-92CE-5E47-BC8C-C0EED691F8D5
# ...
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1          262144         4194270   1.9 GiB     8300  
#   14            2048            8191   3.0 MiB     EF02  
#   15            8192          262143   124.0 MiB   EF00  
mount /dev/nbd0p1 /mnt/
cat << 'EOF' > /mnt/etc/cloud/cloud.cfg.d/99_ovs_dpdk.cfg
datasource_list: ['None']
ssh_pwauth: true
users:
  - name: admin
    # password is secret
    passwd: $y$j9T$bxqxdLbW2jb/yOwSW1BaD.$QXAPgOvsfdFKglwbnrOC.1K5WEl1i7kQpm.WXQA8s9D
    lock_passwd: false
    shell: '/bin/bash'
    sudo: "ALL=(ALL) NOPASSWD:ALL"
package_update: true
packages:
  - openvswitch-switch-dpdk
  - dpdk-dev
  - python3-openvswitch
  - vim
  - iproute2
  - iputils-ping
  - man-db
  - tcpdump
  - docker.io
EOF
umount /mnt/
mount /dev/nbd0p15 /mnt/
cat << 'EOF' > /mnt/startup.nsh
fs0:
EFI\BOOT\BOOTX64.EFI
EOF
umount /mnt/
qemu-nbd --disconnect /dev/nbd0

# DPDK support in Open vSwitch requires privileged container access and /dev/hugepages
# Internet connectivity is required for testing
docker run -ti --init --network bridge --cap-add NET_ADMIN \
    -v /dev/hugepages:/dev/hugepages --privileged -v /tmp/data:/data --name ctr0 \
    ovs-dpdk:local \
    /bin/sh -c \
    '/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start && bash'
```

Run the following commmands in the previously started shell inside the Docker container:

```sh
cd /data

update-alternatives --set ovs-vswitchd /usr/lib/openvswitch-switch-dpdk/ovs-vswitchd-dpdk
/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname stop
/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start

# prepare Open vSwitch bridge
ovs-vsctl set Open_vSwitch . "other_config:dpdk-init=true"
ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vsctl set Open_vSwitch . other_config:vhost-iommu-support=true

ip link add ctr0-left type veth peer name ctr0-right
ip link set ctr0-left up
ip link set ctr0-right up
ip addr add 192.168.0.1/24 dev ctr0-left

ovs-vsctl --may-exist add-br br0 \
  -- set Bridge br0 datapath_type=netdev \
  -- br-set-external-id br0 bridge-id br0 \
  -- set bridge br0 fail-mode=standalone

ovs-vsctl add-port br0 ctr0-right

# Ref.: /usr/share/doc/ovmf/README.Debian
cp -raiv /usr/share/OVMF/OVMF_VARS_4M.ms.fd debian_VARS.fd

qemu-system-x86_64 -name debian -m 8G -cpu host -smp 4 \
    -machine q35,accel=kvm,smm=on,kernel-irqchip=split \
    -object memory-backend-memfd,id=mem,share=on,size=8G,hugetlb=on \
    -numa node,cpus=0-3,memdev=mem -mem-prealloc \
    -nographic \
    -drive file=debian.qcow2,media=disk,if=virtio \
    -boot menu=on \
    -device intel-iommu,intremap=on,device-iotlb=on \
    -net nic,model=virtio,addr=0x10 \
    -net user,hostfwd=tcp::10022-:22,ipv6=off \
    -device virtio-net-pci,mac=00:00:00:00:00:0a,netdev=mynet0,addr=0x11,disable-legacy=on,disable-modern=off,iommu_platform=on,ats=on \
    -netdev tap,id=mynet0,ifname=tap1337,vhostforce=on,queues=128,script=no,downscript=no \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file="/usr/share/OVMF/OVMF_CODE_4M.ms.fd",readonly=on \
    -drive if=pflash,format=raw,unit=1,file="debian_VARS.fd" \
    -virtfs local,path=/data,mount_tag=host0,security_model=passthrough,id=host0
```

Once the virtual machine has booted, open another shell at your container host and run:

```sh
docker exec ctr0 ip link set tap1337 up
docker exec ctr0 ovs-vsctl add-port br0 tap1337
docker exec ctr0 ovs-vsctl show
docker exec -t ctr0 tcpdump -i any -en # in another tty
```

Again open another shell at your container host and run:

```sh
docker exec -ti ctr0 ssh -p 10022 admin@localhost
```

Log in as `admin` with password `secret` and enter the following commands:

```sh
sudo -s
mokutil --sb-state
# SecureBoot enabled
cat /sys/kernel/security/lockdown
# none [integrity] confidentiality

echo 2048 > /proc/sys/vm/nr_hugepages

modprobe vfio enable_unsafe_noiommu_mode=1
modprobe vfio-pci
dpdk-devbind.py --status net
dpdk-devbind.py -b vfio-pci 0000:00:11.0
dpdk-devbind.py --status net

systemctl restart ovs-vswitchd.service

# prepare Open vSwitch bridge
ovs-vsctl set Open_vSwitch . "other_config:dpdk-init=true"
ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vsctl set Open_vSwitch . other_config:vhost-iommu-support=true

ip link add ctr0-left type veth peer name ctr0-right
ip link set ctr0-left up
ip link set ctr0-right up
ip addr add 192.168.0.2/24 dev ctr0-left

ovs-vsctl --may-exist add-br br0 \
  -- set Bridge br0 datapath_type=netdev \
  -- br-set-external-id br0 bridge-id br0 \
  -- set bridge br0 fail-mode=standalone

ovs-vsctl add-port br0 ctr0-right

ovs-vsctl add-port br0 dpdk-p0 \
    -- set Interface dpdk-p0 type=dpdk options:dpdk-devargs=0000:00:11.0

# Packets will be printed at the previous shell
ping -c 3 -M do -s 1422 192.168.0.1

ovs-vsctl del-br br0
systemctl stop ovs-vswitchd.service
ip link del ctr0-left

docker run -it --init --rm --network bridge --cap-add NET_ADMIN \
    -v /dev/hugepages:/dev/hugepages --privileged --name ctr1 debian:bullseye \
    /bin/bash -c 'apt-get update && apt-get install -y iputils-ping openvswitch-switch-dpdk && bash'
```

Run the following commmands in the previously started shell inside the Docker container:

```sh
/usr/share/openvswitch/scripts/ovs-ctl --no-monitor --system-id=random --no-record-hostname start

# prepare Open vSwitch bridge
ovs-vsctl set Open_vSwitch . "other_config:dpdk-init=true"
ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vsctl set Open_vSwitch . other_config:vhost-iommu-support=true

ip link add ctr0-left type veth peer name ctr0-right
ip link set ctr0-left up
ip link set ctr0-right up
ip addr add 192.168.0.2/24 dev ctr0-left

ovs-vsctl --may-exist add-br br0 \
  -- set Bridge br0 datapath_type=netdev \
  -- br-set-external-id br0 bridge-id br0 \
  -- set bridge br0 fail-mode=standalone

ovs-vsctl add-port br0 ctr0-right

ovs-vsctl add-port br0 dpdk-p0 \
    -- set Interface dpdk-p0 type=dpdk options:dpdk-devargs=0000:00:11.0

# Packets will be printed at the previous shell
ping -c 3 -M do -s 1422 192.168.0.1

exit # leave the shell inside the Docker container.
```

Use `shutdown -h now` to shutdown the virtual machine. Once finished with testing, enter in a shell of the container
host:

```sh
docker kill ctr0
docker rm ctr0
docker rmi ovs-dpdk:local
```
