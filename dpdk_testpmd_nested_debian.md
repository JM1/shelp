# Testing DPDK with dpdk-testpmd in a Debian VM and a nested FCOS VM

Basic DPDK test with a [`dpdk-testpmd`](https://doc.dpdk.org/guides/testpmd_app_ug/) instance running in a QEMU/KVM
based virtual machine on a bare-metal server and another `dpdk-testpmd` instance running inside a nested virtual
machine. The outer virtual machine has UEFI Secure Boot enabled and runs on Debian 11 (Bullseye). The nested virtual
machine runs on Fedora CoreOS but uses BIOS instead of UEFI.

On a bare-metal server with Debian 11 (Bullseye) open a shell and enter:

```sh
sudo -s

# util-linux has nsenter
# iproute2 has ip
# gdisk has sgdisk
# qemu-utils has qemu-img and qemu-nbd
apt install -y iputils-ping iproute2 docker.io wget gdisk kpartx qemu-utils

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
    'apt-get update && apt-get install -y openssh-client openvswitch-switch-dpdk python3-openvswitch vim iproute2 iputils-ping man-db tcpdump dpdk-dev qemu-kvm qemu-system-gui-'
docker commit build1 dpdk-sb:local
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
rm /var/tmp/cosa/src/config/overlay.d/15fcos/etc/ssh/sshd_config.d/40-disable-passwords.conf
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

wget https://cdimage.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2 -O debian.qcow2
qemu-img resize debian.qcow2 16G

sudo -s
modprobe nbd
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
mkdir -p /mnt/tmp1/
mount /dev/nbd0p1 /mnt/tmp1/
cat << 'EOF' > /mnt/tmp1/etc/cloud/cloud.cfg.d/99_ovs_dpdk.cfg
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
  - dpdk-dev
  - docker.io
  # linux-image-amd64 is required for 9p support
  - linux-image-amd64
power_state:
  mode: reboot
EOF
umount /mnt/tmp1/
mount /dev/nbd0p15 /mnt/tmp1/
cat << 'EOF' > /mnt/tmp1/startup.nsh
fs0:
EFI\BOOT\BOOTX64.EFI
EOF
umount /mnt/tmp1/
qemu-nbd --disconnect /dev/nbd0
exit # leave root shell

docker run -ti --init --network bridge --cap-add NET_ADMIN \
    -v /dev/hugepages:/dev/hugepages --privileged -v /tmp/data:/data --name ctr0 \
    dpdk-sb:local /bin/bash
```
Run the following commmands in the previously started shell inside the Docker container:
```sh
cd /data

# Ref.: /usr/share/doc/ovmf/README.Debian
cp -raiv /usr/share/OVMF/OVMF_VARS_4M.ms.fd debian_VARS.fd

qemu-system-x86_64 -accel kvm -name debian -m 16G -cpu host -smp 4 \
    -machine q35,smm=on \
    -object memory-backend-memfd,id=mem,share=on,size=16G,hugetlb=on \
    -numa node,cpus=0-3,memdev=mem -mem-prealloc \
    -nographic \
    -drive file=debian.qcow2,media=disk,if=virtio \
    -boot menu=on \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::10022-:22,ipv6=off \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file="/usr/share/OVMF/OVMF_CODE_4M.ms.fd",readonly=on \
    -drive if=pflash,format=raw,unit=1,file="debian_VARS.fd" \
    -virtfs local,path=/data,mount_tag=host0,security_model=passthrough,id=host0
```
Once the virtual machine has booted, open another shell at your container host and run:
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

apt purge -y linux-image-cloud-amd64 linux-image-5.10.0-21-cloud-amd64
reboot # and login again
sudo -s

mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt/

echo 4096 > /proc/sys/vm/nr_hugepages

docker run -it --init --rm --network bridge --cap-add NET_ADMIN \
    -v /dev/hugepages:/dev/hugepages --privileged -v /mnt:/mnt --name ctr1 debian:bullseye \
    /bin/bash -c 'apt-get update && apt-get install -y dpdk-dev qemu-kvm qemu-system-gui- && bash'
```
Run the following commmands in the previously started shell inside the Docker container:
```sh
dpdk-testpmd --socket-mem=512 -n 4 \
    --vdev 'net_vhost0,iface=/tmp/vhost-user-0' \
    --vdev 'net_vhost1,iface=/tmp/vhost-user-1' \
    -- \
    --portmask=f -i --rxq=1 --txq=1 \
    --nb-cores=3 --forward-mode=io --auto-start
```
Open yet another shell at your container host and run:
```sh
docker exec -ti ctr0 ssh -p 10022 admin@localhost
```
Again log in as `admin` with password `secret` and enter the following commands:
```sh
sudo -s
docker exec -ti ctr1 /bin/bash
```
Run the following commmands in the previously started shell inside the Docker container:
```sh
cd /mnt
qemu-system-x86_64 -accel kvm -name fcos -m 6G -cpu host -smp 4 \
    -object memory-backend-file,id=mem,size=6G,mem-path=/dev/hugepages,share=on \
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
Use `shutdown -h now` to shutdown the nested virtual machine.
Use `exit` to leave the shell inside the Podman container.
Use `shutdown -h now` again to shutdown the outer virtual machine.
Now start the outer virtual machine again but when in UEFI Shell enter `reset –c -fwui` to enter the firmware ui, go
to `Device Manager`, `Secure Boot Configuration`, disable `Attempt Secure Boot` (remove the `[X]`), press Escape
twice and `Reset`. Then continue with UEFI Shell commands and the other commands given above.
Once finished with testing, enter in a shell of the container host:
```sh
docker kill ctr0
docker rm ctr0
docker rmi dpdk-sb:local
```
