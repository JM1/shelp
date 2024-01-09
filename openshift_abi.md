# Multi-node OpenShift cluster with ABI in Podman container with KVM

This guide shows how to deploy an multi-node [OpenShift][ocp] cluster with 3x masters and 2x workers using
[Agent-based Installer][ocp-abi] and run [OpenShift's conformance test suite][ocp-tests]. It uses libvirt domains
(QEMU/KVM based virtual machines) running in a Podman container to simulate bare-metal servers and auxiliary resources.

:warning: **WARNING:** Beware of high resource utilization, e.g. this cluster requires >96GB of RAM. :warning:

[ocp]: https://www.redhat.com/en/technologies/cloud-computing/openshift/container-platform
[ocp-abi]: https://docs.openshift.com/container-platform/4.13/installing/installing_with_agent_based_installer/preparing-to-install-with-agent-based-installer.html
[ocp-tests]: https://github.com/openshift/origin

## Prepare container host

First, install `git` and [Podman][install-podman] on a bare-metal system with Debian 11 (Bullseye), CentOS Stream 8,
Fedora Linux 33, Ubuntu 22.04 LTS (Jammy Jellyfish) or newer. Ensure the system [has KVM nested virtualization enabled][
kvm-nested-virtualization], has enough storage to store disk images for the virtual machines and is **not** connected
to ip networks `192.168.157.0/24` and `192.168.158.0/24`. Then run:

[install-podman]: https://github.com/JM1/ansible-collection-jm1-cloudy/blob/master/README.md#installing-podman
[kvm-nested-virtualization]: https://github.com/JM1/ansible-collection-jm1-cloudy/blob/master/README.md#enable-kvm-nested-virtualization

```sh
git clone https://github.com/JM1/ansible-collection-jm1-cloudy.git
cd ansible-collection-jm1-cloudy/
cp -i ansible.cfg.example ansible.cfg
```

## Provide pull secrets

OpenShift requires [pull secrets][using-image-pull-secrets] to authenticate with container registries `Quay.io` and
`registry.redhat.io`, which serve the container images for OpenShift Container Platform components. Download [pull
secrets][using-image-pull-secrets] from [Red Hat Cloud Console][rh-console-abi] and store them in file `pull-secret.txt`
in repository directory `ansible-collection-jm1-cloudy`.

If you want to deploy an [OpenShift release image build from OpenShift CI][ocp-ci-releases], you also have to get a pull
secret for `registry.ci.openshift.org` ([guide][ocp-custom-builds]): Ensure your GitHub.com user is a member of the
`OpenShift` organization, otherwise [request access here][ocp-github-access]. Then [request an API token][
ocp-auth-token-request], it will be like `sha256~abcdefghijklmnopqrstuvwxyz01234567890abcdef`. Use this token to login
and store it in `pull-secret.txt` with (replace `$GITHUB_USER` and `$API_TOKEN`):

[ocp-auth-token-request]: https://oauth-openshift.apps.ci.l2s4.p1.openshiftapps.com/oauth/token/request
[ocp-ci-releases]: https://amd64.ocp.releases.ci.openshift.org/
[ocp-custom-builds]: https://source.redhat.com/groups/public/palonsor/palonsor_wiki/how_to_perform_custom_builds_of_ocp4_components
[ocp-github-access]: https://source.redhat.com/groups/public/atomicopenshift/atomicopenshift_wiki/openshift_onboarding_checklist_for_github
[rh-console-abi]: https://console.redhat.com/openshift/install/metal/agent-based
[using-image-pull-secrets]: https://docs.openshift.com/container-platform/4.13/openshift_images/managing_images/using-image-pull-secrets.html

```sh
podman login --authfile pull-secret.txt -u $GITHUB_USER -p $API_TOKEN registry.ci.openshift.org
```

**NOTE:** Tokens for `registry.ci.openshift.org` invalidate quickly, so expect to request new tokens monthly.

Grant unprivileged user in Podman container access to pull secrets:

```sh
chmod a+r pull-secret.txt
```

Next, change `host_vars` of Ansible host `lvrt-lcl-session-srv-530-okd-abi-ha-provisioner` to read pull secrets from file
`pull-secret.txt`. Open file `inventory/host_vars/lvrt-lcl-session-srv-530-okd-abi-ha-provisioner.yml` and change variable
`openshift_abi_pullsecret` to:

```yml
openshift_abi_pullsecret: "{{ lookup('ansible.builtin.file', '/home/cloudy/project/pull-secret.txt') }}"
```

## Choose OpenShift release

Edit `openshift_abi_release_image` in file `inventory/host_vars/lvrt-lcl-session-srv-530-okd-abi-ha-provisioner.yml` to the
OpenShift release you want to deploy:

```yml
openshift_abi_release_image: "{{ lookup('ansible.builtin.pipe', openshift_abi_release_image_query) }}"

openshift_abi_release_image_query: |
  curl -s https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/stable-4.14/release.txt \
    | grep 'Pull From: quay.io' \
    | awk -F ' ' '{print $3}'
```

Or:

```yml
openshift_abi_release_image: 'registry.ci.openshift.org/ocp/release:4.14'
```

## Configure NTP servers

When your corporate network blocks access to public NTP servers edit Ansible variable `chrony_config` for host
`lvrt-lcl-session-srv-500-okd-abi-ha-router` in file
`inventory/host_vars/lvrt-lcl-session-srv-500-okd-abi-ha-router.yml`. For example, suppose your internal NTP servers are
grouped in a pool `clock.company.com`, change `chrony_config` to:

```yml
chrony_config:
- ansible.builtin.copy:
    content: |
      allow 192.168.158.0/24
      # Corporate network blocks all NTP traffic except to internal NTP servers.
      pool clock.company.com iburst
    dest: /etc/chrony/conf.d/home.arpa.conf
    mode: u=rw,g=r,o=
    group: root
    owner: root
```

## Start Podman containers

Create Podman networks, volumes and containers, and attach to a container named `cloudy` with:

```sh
cd containers/
sudo DEBUG=yes DEBUG_SHELL=yes ./podman-compose.sh up
```

Inside this container a Bash shell will be spawned for user `cloudy`. This user `cloudy` will be executing the libvirt
domains (QEMU/KVM based virtual machines).

## Deploy OpenShift cluster

Launch the first set of virtual machines with the following commands run from `cloudy`'s Bash shell:

```sh
ansible-playbook playbooks/site.yml --limit \
lvrt-lcl-session-srv-500-okd-abi-ha-router,\
lvrt-lcl-session-srv-501-okd-abi-ha-bmc,\
lvrt-lcl-session-srv-510-okd-abi-ha-cp0,\
lvrt-lcl-session-srv-511-okd-abi-ha-cp1,\
lvrt-lcl-session-srv-512-okd-abi-ha-cp2,\
lvrt-lcl-session-srv-520-okd-abi-ha-w0,\
lvrt-lcl-session-srv-521-okd-abi-ha-w1
```

The former sets up a router which provides DHCP, DNS and NTP services and internet access. It starts [sushy-emulator][
sushy-emulator] to provide a virtual Redfish BMC to power cycle servers and mount virtual media for hardware inspection
and provisioning. It will also create virtual machines for OpenShift's master nodes and worker nodes, but without an
operating system and in stopped/shutdown state.

[sushy-emulator]: https://docs.openstack.org/sushy-tools/latest/user/dynamic-emulator.html

**NOTE:** When Ansible execution fails, try to run the Ansible playbook again.

Launch another virtual machine to run OpenShift [ABI][ocp-abi] and deploy the OpenShift cluster:

```sh
ansible-playbook playbooks/site.yml \
  --limit lvrt-lcl-session-srv-530-okd-abi-ha-provisioner \
  --skip-tags jm1.cloudy.openshift_tests
```

## Access OpenShift cluster

To access the cluster when Ansible is done, connect to the virtual machine which initiated the cluster installation
(Ansible host `lvrt-lcl-session-srv-530-okd-abi-ha-provisioner`):

```sh
ssh ansible@192.168.158.48
```

The cluster uses internal DHCP and DNS services which are not accessible from the container host. In order to connect to
the virtual machine from another shell at the container host (the bare-metal system) run:

```sh
sudo podman exec -ti -u cloudy cloudy ssh ansible@192.168.158.48
```

From `ansible`'s Bash shell at `lvrt-lcl-session-srv-530-okd-abi-ha-provisioner` the cluster can be accessed with:

```sh
export KUBECONFIG=/home/ansible/clusterconfigs/auth/kubeconfig
oc get nodes
oc debug node/cp0
```

## Run test suite

Back at `cloudy`'s Bash shell inside the container, run [OpenShift's conformance test suite][ocp-tests] with:

```sh
ansible-playbook playbooks/site.yml \
  --limit lvrt-lcl-session-srv-530-okd-abi-ha-provisioner \
  --tags jm1.cloudy.openshift_tests
```

## Tear down environment

Remove all virtual machines with:

```sh
# Note the .home.arpa suffix
for vm in \
  lvrt-lcl-session-srv-500-okd-abi-ha-router.home.arpa \
  lvrt-lcl-session-srv-501-okd-abi-ha-bmc.home.arpa \
  lvrt-lcl-session-srv-510-okd-abi-ha-cp0.home.arpa \
  lvrt-lcl-session-srv-511-okd-abi-ha-cp1.home.arpa \
  lvrt-lcl-session-srv-512-okd-abi-ha-cp2.home.arpa \
  lvrt-lcl-session-srv-520-okd-abi-ha-w0.home.arpa \
  lvrt-lcl-session-srv-521-okd-abi-ha-w1.home.arpa \
  lvrt-lcl-session-srv-530-okd-abi-ha-provisioner.home.arpa
do
    virsh destroy "$vm"
    virsh undefine --remove-all-storage --nvram "$vm"
done
```

Removal does not impose any order.

Exit `cloudy`'s Bash shell to stop the container.

**NOTE:** Any virtual machines still running inside the container will be killed!

Finally, remove all Podman containers, networks and volumes with:

```sh
sudo DEBUG=yes ./podman-compose.sh down
```
