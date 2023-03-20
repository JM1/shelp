# Open vSwitch

* [Connecting Docker containers with Open vSwitch bridges using the kernel datapath and VXLAN](ovs_kernel_dp.sh)
* [Connecting Docker containers with Open vSwitch bridges using the userspace datapath and VXLAN](ovs_userspace_dp.sh)
* [Hands-on introduction to Open vSwitch and OpenFlow](ovs_openflow_arp.md)
* [Building ARP and ICMP responders in Open vSwitch using OpenFlow tables](ovs_openflow_arp_icmp.md)
* [Attaching a QEMU/KVM VM to a Open vSwitch bridge using DPDK vHost User ports](ovs_dpdk_vhost_user.md)
* [Creating a Open vSwitch bridge with DPDK and `virtio-pmd` in a QEMU/KVM VM](ovs_dpdk_virtio_pmd.md)

## Resources

* [OpenFlow Switch specifications](https://opennetworking.org/software-defined-standards/specifications/), esp.:
  - [OpenFlow Switch Specification 1.0.0](
    https://opennetworking.org/wp-content/uploads/2013/04/openflow-spec-v1.0.0.pdf)
  - [OpenFlow Switch Specification 1.1.0](
    https://opennetworking.org/wp-content/uploads/2014/10/openflow-spec-v1.1.0.pdf) introduces support for a pipeline
    with groups, instructions and multiple flow tables etc.
  - [OpenFlow Switch Specification 1.2.0](
    https://opennetworking.org/wp-content/uploads/2014/10/openflow-spec-v1.2.pdf) brings support for IPv6 and and a new
    extensible flow match header with a variable number of flow match fields and a new "OpenFlow Extensible Match" (OXM)
    type `OFPMT_OXM`.
  - Changelogs of [OpenFlow Switch Specification 1.3.0](
    https://opennetworking.org/wp-content/uploads/2014/10/openflow-spec-v1.3.0.pdf),
    [OpenFlow Switch Specification 1.4.0](
    https://opennetworking.org/wp-content/uploads/2014/10/openflow-spec-v1.4.0.pdf) and
    [OpenFlow Switch Specification 1.5.0](
    https://opennetworking.org/wp-content/uploads/2014/10/openflow-switch-v1.5.0.pdf)
* [The Design and Implementation of Open vSwitch by Ben Pfaff et al. (2015)](
  https://www.openvswitch.org/support/papers/nsdi2015.pdf) explains the architecture of Open vSwitch including its
  first-level Microflow chache and its second-level Megaflow cache and evaluates Open vSwitch's cache layer
  performance.
* [Open vSwitch's documentation of protocol header fields in OpenFlow and Open vSwitch aka `man ovs-fields`](
  https://manpages.debian.org/unstable/openvswitch-common/ovs-fields.7.en.html) features an extensive discussion of
  the evolution of OpenFlow fields across different OpenFlow specifications.
* [Open vSwitch's documentation of OpenFlow actions, instructions and extensions aka `man ovs-actions`](
  https://manpages.debian.org/unstable/openvswitch-common/ovs-actions.7.en.html)
