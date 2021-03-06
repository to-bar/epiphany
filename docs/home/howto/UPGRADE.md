## Upgrade

### Prerequisites

Before k8s version upgrade make sure that deprecated API versions are not used:

1. [v1.17](https://v1-17.docs.kubernetes.io/docs/setup/release/notes/#deprecations-and-removals)
2. [v1.18](https://v1-18.docs.kubernetes.io/docs/setup/release/notes/#deprecation)

### Introduction

From Epicli 0.4.2 and up the CLI has the ability to perform upgrades on certain components on a cluster. The components it currently can upgrade and will add are:

*Note: Since v0.7.0 Epiphany does not support k8s version upgrades older than 1.14.6 (Epiphany v0.4.4).
There is an assertion to check whether K8s version is supported before running upgrade,
but upgrade for v0.3.1 is not possible due to the open [issue](https://github.com/epiphany-platform/epiphany/issues/1491).*

- Kubernetes (master and nodes): starting from version 1.14.6 to 1.18.6
- common: Upgrades all common configurations to match them to current Epiphany version
- repository: Adds the repository role needed for component installation in current Epiphany version
- image_registry: Adds the image_registry role needed for offline installation in current Epiphany version

*Note: The component upgrade takes the existing Ansible build output and based on that performs the upgrade of the currently supported components. If you need to upgrade your entire Epiphany cluster a **manual** upgrade of the input yaml is needed to the latest specification which then should be applied with `epicli apply...` after the offline upgrade which is described here.*

### Online upgrade

#### Online prerequisites

Your airgapped existing cluster should meet the following requirements:

1. The cluster machines/vm`s are connected by a network or virtual network of some sorts and can communicate which each other and have access to the internet:
2. The cluster machines/vm`s are **upgraded** to the following versions:
    - RedHat 7.6
    - CentOS 7.6
    - Ubuntu 18.04
3. The cluster machines/vm`s should be accessible through SSH with a set of SSH keys you provided and configured on each machine yourself.
4. A provisioning machine that:
    - Has access to the SSH keys
    - Has access to the build output from when the cluster was first created.
    - Is on the same network as your cluster machines
    - Has Epicli 0.4.2 or up running.
      *Note. To run Epicli check the [Prerequisites](./PREREQUISITES.md)*

#### Start the online upgrade

Start the upgrade with:

```shell
epicli upgrade -b /buildoutput/
```

This will backup and upgrade the Ansible inventory in the provided build folder `/buildoutput/` which will be used to perform the upgrade of the components.

### Offline upgrade

#### Offline prerequisites

Your airgapped existing cluster should meet the following requirements:

1. The airgapped cluster machines/vm`s are connected by a network or virtual network of some sorts and can communicate which each other:
2. The airgapped cluster machines/vm`s are **upgraded** to the following versions:
    - RedHat 7.6
    - CentOS 7.6
    - Ubuntu 18.04
3. The airgapped cluster machines/vm`s should be accessible through SSH with a set of SSH keys you provided and configured on each machine yourself.
4. A requirements machine that:
    - Runs the same distribution as the airgapped cluster machines/vm`s (RedHat 7, CentOS 7, Ubuntu 18.04)
    - Has access to the internet.
5. A provisioning machine that:
    - Has access to the SSH keys
    - Has access to the build output from when the cluster was first created.
    - Is on the same network as your cluster machines
    - Has Epicli 0.4.2 or up running.
      *Note. To run Epicli check the [Prerequisites](./PREREQUISITES.md)*

#### Start the offline upgrade

To upgrade the cluster components run the following steps:

1. First we need to get the tooling to prepare the requirements for the upgrade. On the provisioning machine run:

    ```shell
    epicli prepare --os OS
    ```

    Where OS should be `centos-7`, `redhat-7`, `ubuntu-18.04`. This will create a directory called `prepare_scripts` with the following files inside:

    - download-requirements.sh
    - requirements.txt
    - crane_x86_64

2. The scripts in the `prepare_scripts` will be used to download all requirements. To do that copy the `prepare_scripts` folder over to the requirements machine and run the following command:

    ```shell
    download-requirements.sh /requirementsoutput/
    ```

    This will start downloading all requirements and put them in the `/requirementsoutput/` folder. Once run succesfully the `/requirementsoutput/` needs to be copied to the provisioning machine to be used later on.

3. Finally start the upgrade with:

    ```shell
    epicli upgrade -b /buildoutput/ --offline-requirements /requirementsoutput/
    ```

    This will backup and upgrade the Ansible inventory in the provided build folder `/buildoutput/` which will be used to perform the upgrade of the components. The `--offline-requirements` flag tells Epicli where to find the requirements folder (`/requirementsoutput/`) prepared in steps 1 and 2 which is needed for the offline upgrade.

### Additional parameters

The `epicli upgrade` command has additional flags:
- `--wait-for-pods`. When this flag is added, the Kubernetes upgrade will wait until all pods are in the **ready** state before proceding. This can be usefull when a zero downtime upgrade is required. **Note: that this can also cause the upgrade to hang indefinitely.**
- `--upgrade-components`. Specify comma separated component names so the upgrade procedure will only process specific ones. List cannot be empty, otherwise execution will fail. By default, upgrade will process all components if this parameter is not provided.
   Example:
   ```shell
   epicli upgrade -b /buildoutput/ --upgrade-components "kafka,filebeat"
   ```

## How to upgrade Kafka

### Kafka upgrade

Kafka will be automatically updated to the latest version supported by Epiphany. You can check latest supported version [here](../COMPONENTS.md#epiphany-cluster-components). Kafka brokers are updated one by one - but the update procedure does not guarantee "zero downtime" because it depends on the number of available brokers, topic, and partitioning configuration.

### ZooKeeper upgrade

ZooKeeper redundancy is also recommended, since service restart is required during upgrade - it can cause ZooKeeper unavailability. Having at **least two ZooKeeper services** in *ZooKeepers ensemble* you can upgrade one and then start with the rest **one by one**.

More detailed information about ZooKeeper you can find in  [ZooKeeper documentation](https://cwiki.apache.org/confluence/display/ZOOKEEPER).

## Open Distro for Elasticsearch upgrade

---
**NOTE**

Before upgrade procedure make sure you have a data backup!

---

In Epiphany v0.8.0 we provided upgrade elasticsearch-oss package to v7.9.1 and opendistro-* plugins package to v1.10.1.
Upgrade will be performed automatically when the upgrade procedure detects your `logging`, `opendistro_for_elasticsearch` or `kibana` hosts.

Upgrade of elasticsearch-oss package uses API calls (GET, PUT, POST) which requires an admin TLS certificate. By defult,
the demo certificate is used so before starting the upgrade, you may need to specify your admin certificate by editing these properties:

```shell
specification.api.auth.tls.client_cert
specification.api.auth.tls.client_key
```

They are accessible via the defaults of `opendistro_for_elasticsearch` role (`/usr/local/epicli/data/common/ansible/playbooks/roles/opendistro_for_elasticsearch/defaults/main.yml`).

## Node exporter upgrade

---
**NOTE**

Before upgrade procedure make sure you have a data backup and you are familiar with [breaking changes](https://github.com/prometheus/node_exporter/releases/tag/v1.0.0).

---

Starting from Epiphany v0.8.0 it's possible to upgrade node exporter to v1.0.1.
Upgrade will be performed automatically when the upgrade procedure detects node exporter hosts.

## RabbitMQ upgrade

---
**NOTE**

Before upgrade procedure make sure you have a data backup.
Check that the node or cluster is in a good state: no alarms are in effect,
no ongoing queue synchronisation operations and the system is otherwise under a reasonable load.
For more information visit RabbitMQ [site](https://www.rabbitmq.com/upgrade.html).

---

With the latest Epiphany version it's possible to upgrade RabbitMQ to v3.8.9.
It requires Erlang system packages upgrade that is done automatically to v23.1.4.
Upgrade is performed in offline mode after stopping all RabbitMQ nodes.
[Rolling upgrade](https://www.rabbitmq.com/upgrade.html#rolling-upgrades) is not supported by Epiphany and it is advised not to use this approach when Erlang needs to be upgraded.
