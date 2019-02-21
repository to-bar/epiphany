# Epiphany CLI design document

Affected version: 0.2.1

## Goals

Provide simple in use cli that will:

1. provide input validation (cmd arguments and data file)
2. maintain Epiphany cluster state (json file, binary, tbd)
3. allow to create empty project (via command-line and data file)
4. maintain information about Epiphany version used on each machine (unique identifier generation?)
5. allow to add/remove resources via data file.
    - separate infrastructure data files from configuration
    - internal file with default values will be created
6. allow to add resources via command-line (networks, vpn, servers, roles, etc.)
7. allow all messages from cli to be convertible to json/yaml (like -o yaml, -o json)
8. plugable storage/vault for Epiphany state and Terraform state

## Use cases

### CLI deployments/management usage

Create empty cluster:

```bash
> epiphany create cluster --name='epiphany-first-cluster'
```

Add resources to cluster:

```bash
> epiphany add machine --create --azure --size='Standard_DS2_v2' --name='master-vm-hostname'
> epiphany add master -vm 'master-vm-hostname'
> ...
```

Read information about cluster:

```bash
> epiphany get cluster-info --name='epiphany-first-cluster'
```

CLI arguments should override default values which will be provided almost for every aspect of the cluster.

### Data driven deployments/management usage - Configuration and Infrastructure definition separation

While CLI usage will be good for dev and testing, production environments should be created using data files.

Data required for creating infrastructure (like network, vm, disk creation) should be separated from configuration (Kubernetes, Kafka, etc.).

Each data file should have following data in header:

```yaml
kind: configuration/component-name # configuration/kubernetes, configuration/kafka, configuration/monitoring, ...
version: X.Y.Z
title: my-component-configuration
specification:
    # ...
```

Many configuration files will be handled using `---` document separator. Like:

```yaml
kind: configuration/kubernetes
# ...
---
kind: configuration/kafka
# ...
```

Creating infrastructure will be similar but it will use another file kinds. It should look like:

```yaml
kind: infrastructure/server
version: X.Y.Z
title: my-server-infra-specification
specification:
    # ...
```

### One to rule them all

Same as many configurations can be enclosed in one file with `---` separator, configuration and infrastructure `yamls` should also be treated in that way.

Example:

```yaml
kind: configuration/kubernetes
# ...
---
kind: configuration/kafka
# ...
---
kind: infrastructure/server
#...
```

## Proposed design - Big Picture

![Epiphany engine architecture proposal](epiphany-engine.svg)

### Input

Epiphany engine console application will be able to handle configuration file and/or commands.

Command and data files will be merged with default values defined as a file in application directory, into Model that from now on will be used for configuration. If data file (or command argument) will contain some values, those values should override defaults.

### Infrastructure

Data file, based on which infrastructure will be created should have exactly same structure as input file. It means, user can define all values - and based on that VMs, Networks, Disks, etc. will be created, or he can add just a few required values and rest will be added from defaults to final data file. Some of the values - like machine IPs (and probably some more) have to be determined at runtime.

### Configuration

Managing configuration file should look similar to infrastructure file with difference of There will be values that have to be retrieved from infrastructure data.

### State

State will be result of creating platform (aka build). It should be stored in configured location (storage, vault, directory). State will contain all documents that took part in platform creation.