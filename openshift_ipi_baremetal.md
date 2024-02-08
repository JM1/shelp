# Bare-metal provisioning with OpenShift Installer-provisioned installation (IPI)

This page analyses the steps and components used by [OpenShift][ocp]'s [Installer-provisioned installation (IPI)][
ocp-ipi] when deploying a multi-node cluster on bare-metal servers. It assumes the reader is familiar with the overall
[architecture][ocp-ipi] and [workflow][ocp-ipi-workflow] of IPI and has successfully deployed an OpenShift or OKD
cluster using IPI before ([guide](openshift_ipi.md)).

[ocp]: https://www.redhat.com/en/technologies/cloud-computing/openshift/container-platform
[ocp-ipi]: https://docs.openshift.com/container-platform/4.14/installing/installing_bare_metal_ipi/ipi-install-overview.html
[ocp-ipi-workflow]: https://docs.openshift.com/container-platform/4.14/installing/installing_bare_metal_ipi/ipi-install-installation-workflow.html
[ocp-installer]: https://github.com/openshift/installer

[tfvars-baremetal-hosts]: https://github.com/openshift/installer/blob/ef713aa74d19dc609bdfdae682fe794e9097cafd/pkg/tfvars/baremetal/baremetal.go#L80
[terraform-provider-ironic]: https://github.com/openshift-metal3/terraform-provider-ironic
[ocp-installer-baremetal-hosts]: https://github.com/openshift/installer/blob/ef713aa74d19dc609bdfdae682fe794e9097cafd/pkg/asset/machines/baremetal/hosts.go#L127
[ocp-baremetal-operator]: https://github.com/openshift/baremetal-operator/

[Installer-provisioned installation (IPI)][ocp-ipi] is a part of and triggered by [OpenShift Installer][ocp-installer].

When [creating OpenShift Container Platform manifests][ocp-ipi-workflow] with [OpenShift Installer][ocp-installer], i.e.
`openshift-baremetal-install create manifests`, the bare-metal nodes listed in `install-config.yaml` are turned [into
TerraForm variables][tfvars-baremetal-hosts] for the [Terraform provider for Ironic][terraform-provider-ironic] and
[into `BareMetalHost` resources][ocp-installer-baremetal-hosts] for [Metal³'s Bare Metal Operator][
ocp-baremetal-operator].

When OpenShift Installer, i.e. `openshift-baremetal-install create cluster`, is [run to deploy a cluster][
ocp-ipi-workflow], it starts a bootstrap VM at the provisioner host using Terraform ([stages][
ocp-installer-tf-bm-stages], [variables][ocp-installer-tf-bm-variables]).
Master nodes are bootstrapped with [Ironic][metal3-book-ironic] in Podman containers with help of the [Bare Metal
Operator][metal3-book-bmo] (in the bootstrap control plane) running on the bootstrap VM. Worker nodes are provisioned
later using the same components but running on the control plane provided by the master nodes.

[metal3-book-bmo]: https://book.metal3.io/bmo/introduction
[metal3-book-ironic]: https://book.metal3.io/ironic/introduction
[ocp-installer-tf-bm-stages]: https://github.com/openshift/installer/blob/master/pkg/terraform/stages/baremetal/stages.go
[ocp-installer-tf-bm-variables]: https://github.com/openshift/installer/tree/master/data/data/baremetal

The bootstrap VM will run [build-ironic-env.service][build-ironic-env-service] which in turn will run
[build-ironic-env.sh][build-ironic-env-sh] to prepare an environment, in particular extract container image urls, for
[Metal³'s Bare Metal Operator][ocp-baremetal-operator], [Machine Image Customization Controller][
ocp-image-customization-controller], [Metal3 Ironic Container][ocp-ironic-image] and others. Afterwards, the bootstrap
VM will [run these services as Podman containers][ocp-installer-containers].

[build-ironic-env-service]: https://github.com/openshift/installer/blob/master/data/data/bootstrap/baremetal/systemd/units/build-ironic-env.service.template
[build-ironic-env-sh]: https://github.com/openshift/installer/blob/master/data/data/bootstrap/baremetal/files/usr/local/bin/build-ironic-env.sh
[ocp-image-customization-controller]: https://github.com/openshift/image-customization-controller
[ocp-installer-containers]: https://github.com/openshift/installer/tree/master/data/data/bootstrap/baremetal/files/etc/containers/systemd
[ocp-ironic-image]: https://github.com/openshift/ironic-image

The [Machine Image Customization Controller][ocp-image-customization-controller] will build "a CoreOS live image
customized with an Ignition file to start the [Ironic Python Agent (IPA)][ironic-python-agent] and containing any
per-host network data provided in NMState format" and will serve it "from a webserver built in to the controller". It
will be run on the bootstrap VM as Podman container [image-customization][image-customization-container]. The script
[setup-image-data.sh][setup-image-data-sh] is responsible for pulling the NMState network data for each master node from
[Bare Metal Operator][ocp-baremetal-operator] which runs on the bootstrap control plane. The CoreOS images has been
extracted before with [extract-machine-os.service][extract-machine-os-service].

[extract-machine-os-service]: https://github.com/openshift/installer/blob/master/data/data/bootstrap/baremetal/systemd/units/extract-machine-os.service
[image-customization-container]: https://github.com/openshift/installer/blob/master/data/data/bootstrap/baremetal/files/etc/containers/systemd/image-customization.container
[setup-image-data-sh]: https://github.com/openshift/installer/blob/master/data/data/bootstrap/baremetal/files/usr/local/bin/setup-image-data.sh.template

The [Metal3 Ironic Container][ocp-ironic-image], also running at the bootstrap VM, will be fed with configuration data
about the master nodes by the [Terraform provider for Ironic][terraform-provider-ironic] from [OpenShift Installer][
ocp-installer]. It will launch, inspect and deploy each master node from a tailored CoreOS live image which was created
by [Machine Image Customization Controller][ocp-image-customization-controller] earlier. The CoreOS live image runs the
[Ironic Agent Container][ironic-agent-image] which contains the [Ironic Python Agent (IPA)][ironic-python-agent] for
communication with Ironic as well as the [ironic_coreos_install.py][ironic-coreos-install] script.
The latter will run the custom deployment step [install_coreos][ironic-agent-install-coreos] which will use
[coreos-installer][coreos-installer] to install CoreOS to disk together with a suitable Ignition config, network config
and kernel arguments to bring up that master node.

[coreos-installer]: https://github.com/coreos/coreos-installer
[ironic-coreos-install]: https://github.com/openshift/ironic-agent-image/blob/main/hardware_manager/ironic_coreos_install.py
[ironic-python-agent]: https://docs.openstack.org/ironic-python-agent/latest/
[ironic-agent-image]: https://github.com/openshift/ironic-agent-image
[ironic-agent-install-coreos]: https://github.com/openshift/ironic-agent-image/blob/a14b7ea730ff79ac5f88a41f9a117bd19eba1874/hardware_manager/ironic_coreos_install.py#L183

While [Ironic][ocp-ironic-image] is running on the bootstrap VM, another service [master-bmh-update.service][
master-bmh-update-service], i.e. script [master-bmh-update.sh][master-bmh-update-sh], will be started. It waits until
the Bare Metal Operator has been started on the bootstrap control plane, has been populated with `BareMetalHost`
resources and Ironic has finished the hardware introspection of all master nodes. It will then update the Bare Metal
Operator with the introspection results and shutdown Ironic on the bootstrap VM so that the API VIP can fail over to the
control plane which is running on the master nodes by now.

[master-bmh-update-service]: https://github.com/openshift/installer/blob/master/data/data/bootstrap/baremetal/systemd/units/master-bmh-update.service
[master-bmh-update-sh]: https://github.com/openshift/installer/blob/master/data/data/bootstrap/baremetal/files/usr/local/bin/master-bmh-update.sh

When master nodes have been provisioned successfully, Terraform will destroy the bootstrap VM. The master nodes will now
run the control plane exclusively. The Bare Metal Operator and Ironic running on the master nodes' control plane will
then provision all worker nodes.
