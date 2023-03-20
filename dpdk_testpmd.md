# Testing DPDK with dpdk-testpmd on a bare-metal server and in a virtual machine

Basic DPDK test with [dpdk-testpmd](https://doc.dpdk.org/guides/testpmd_app_ug/) instances running on a bare-metal
server and in a QEMU/KVM based virtual machine.

On a bare-metal server with Debian 11 (Bullseye) open a shell and enter:

```sh
sudo -s

# util-linux has nsenter
# iproute2 has ip
apt install -y iputils-ping iproute2 util-linux docker.io

# Allocate huge pages and mount them at /dev/hugepages
# Ref.:
# https://docs.openvswitch.org/en/latest/intro/install/dpdk/
# https://www.kernel.org/doc/html/latest/admin-guide/mm/hugetlbpage.html
mountpoint /dev/hugepages

exit # leave root shell

# python3-openvswitch is required for ovs-tcpdump
# dpdk-dev has testpmd
docker run -t --init --name build1 debian:bullseye \
    /bin/bash -c \
    'apt-get update && apt-get install -y openvswitch-switch-dpdk python3-openvswitch vim iproute2 iputils-ping man-db tcpdump dpdk-dev qemu-kvm qemu-system-gui-'
docker commit build1 dpdk:local
docker rm build1

# prebuild fcos has no dpdk and no dpdk-tools
#docker run --pull=always --rm -v /tmp/data:/data -w /data quay.io/coreos/coreos-installer:release download -f iso

# build is done in /var/tmp/cosa because cosa wants to set xattrs which tmpfs does not provide by default?!?
cosa() {
    docker run --rm -ti --security-opt label=disable --privileged \
    -v /var/tmp/cosa:/srv/ --device /dev/kvm --device /dev/fuse \
    --tmpfs /tmp -v /var/tmp:/var/tmp \
    quay.io/coreos-assembler/coreos-assembler:latest "$@"
}

cosa init https://github.com/coreos/fedora-coreos-config
sed -i '/^packages:$/a\ \ - dpdk' /var/tmp/cosa/src/config/manifests/fedora-coreos.yaml
sed -i '/- dpdk$/a\ \ - dpdk-tools' /var/tmp/cosa/src/config/manifests/fedora-coreos.yaml
# python3 is required for dpdk-tools but is blacklisted in fcos
sed -i 's/^  - python3$//g' /var/tmp/cosa/src/config/manifests/fedora-coreos.yaml
sed -i 's/^  - python3-libs$//g' /var/tmp/cosa/src/config/manifests/fedora-coreos.yaml
cosa fetch
cosa build metal metal4k # metal and metal4k are required for cosa buildextend-live
cosa buildextend-live

# debug
cosa shell

mkdir /tmp/data
cd /tmp/data

# Define a Butane config, convert it to a Ignition config and prepare a Fedora CoreOS live iso
cp -raiv /var/tmp/cosa/builds/latest/x86_64/fedora-coreos-*-live.*.iso /tmp/data/

cat << 'EOF' > live.bu
variant: fcos
version: 1.4.0
passwd:
  users:
    - name: admin
      # password is secret
      password_hash: $y$j9T$bxqxdLbW2jb/yOwSW1BaD.$QXAPgOvsfdFKglwbnrOC.1K5WEl1i7kQpm.WXQA8s9D
      groups:
        - sudo
        - wheel
EOF
docker run -i --pull=always --rm quay.io/coreos/butane:release --pretty --strict < live.bu > live.ign

coreos_iso=$(compgen -G "fedora-coreos-*-live.*.iso" | grep -v '.sig$' | sort | tail -n 1)
docker run --rm -v /tmp/data:/data -w /data quay.io/coreos/coreos-installer:release iso customize \
    --live-ignition live.ign \
    --live-karg-append 'console=ttyS0,115200' \
    --live-karg-append 'earlyprintk=ttyS0,115200' \
    --live-karg-delete 'console=tty0' \
    -o "live.iso" "$coreos_iso"

docker run -ti --init --detach --cap-add NET_ADMIN \
    -v /dev/hugepages:/dev/hugepages --privileged -v /tmp/data:/data --name ctr0 \
    dpdk:local /bin/bash

docker exec -ti --detach ctr0 dpdk-testpmd -l 0,2,3,4,5 --socket-mem=1024 -n 4 \
    --vdev 'net_vhost0,iface=/tmp/vhost-user-0' \
    --vdev 'net_vhost1,iface=/tmp/vhost-user-1' \
    -- \
    --portmask=f -i --rxq=1 --txq=1 \
    --nb-cores=4 --forward-mode=io --auto-start

docker exec -ti ctr0 /bin/bash
```

Run the following commmands in the previously started shell inside the Docker container:

```sh
# When UEFI Secure Boot is enabled at the container host, the following rename might be necessary to avoid kernel
# message "Lockdown: dpdk-testpmd: raw io port access is restricted; see man kernel_lockdown.7" and avoid a lack of
# connectivity between both dpdk-testpmd instances
cd /usr/lib/x86_64-linux-gnu/dpdk/pmds-21.0/
mv -i librte_net_virtio.so.21.0 librte_net_virtio.so.21.0.old

cd /data
qemu-system-x86_64 -accel kvm -name fcos -m 8G -cpu host -smp 4 \
    -object memory-backend-memfd,id=mem,share=on,size=8G,hugetlb=on \
    -numa node,cpus=0-3,memdev=mem -mem-prealloc \
    -nographic \
    -cdrom live.iso \
    -chardev socket,id=char0,path=/tmp/vhost-user-0 \
    -netdev type=vhost-user,id=mynet0,chardev=char0,vhostforce \
    -device virtio-net-pci,mac=00:00:00:00:00:0a,netdev=mynet0,addr=0x10 \
    -chardev socket,id=char1,path=/tmp/vhost-user-1 \
    -netdev type=vhost-user,id=mynet1,chardev=char1,vhostforce \
    -device virtio-net-pci,mac=00:00:00:00:00:0b,netdev=mynet1,addr=0x11
```

Once the virtual machine has booted, log in as `admin` with password `secret` and enter the following commands:

```sh
sudo -s

modprobe vfio enable_unsafe_noiommu_mode=1
modprobe vfio-pci
dpdk-devbind.py --status net
dpdk-devbind.py -b vfio-pci 0000:00:10.0 0000:00:11.0
dpdk-devbind.py --status net

echo 512 > /proc/sys/vm/nr_hugepages
dpdk-testpmd -l 0,1,2 --socket-mem 1024 -n 4 \
    --proc-type auto --file-prefix pg -- \
    --portmask=3 --forward-mode=macswap --port-topology=chained \
    --disable-rss -i --rxq=1 --txq=1 \
    --rxd=256 --txd=256 --nb-cores=2
```

Inside the `dpdk-testpmd` shell (starting with `testpmd>`) enter the following commands:

```sh
start tx_first
show port stats all
quit
```

Use `shutdown -h now` to shutdown the virtual machine. Use `exit` to leave the shell inside the Docker container.
In a shell of the container host enter:

```sh
docker kill ctr0
docker rm ctr0
docker rmi dpdk:local
```
