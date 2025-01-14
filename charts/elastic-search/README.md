# Elasticsearch Helm Chart

This Helm chart deploys Elasticsearch instances on Kubernetes with support for multiple deployments.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- ECK Operator 2.16.0+ installed in the cluster

## Features

- Optional node placement and zone awareness
- Optional Azure integration for enhanced features
- Automatic plugin installation
- Kibana deployment with secure authentication
- Multiple deployment modes: Basic and Azure-integrated

## Deployment Modes

### Basic Mode (Default)
When deployed without any additional configuration, the chart will:
- Deploy Elasticsearch with ECK operator management
- Configure Kibana with secure service account authentication
- Use default node placement

### Node Placement Mode
When nodeSelector configuration is provided, the chart enables:
- Specific node pool targeting
- Zone awareness for high availability
- Custom toleration support

### Azure-Integrated Mode
When Azure configuration is provided, the chart enables:
- Azure Blob Storage integration for snapshots
- Azure App Configuration integration
- Workload Identity integration for secure Azure authentication
- Custom authentication via provided secrets

## High Availability Architecture

Each Elasticsearch instance is configured for high availability when node placement is enabled:

- Automatically deploys as a 3-node cluster (managed by ECK)
- Nodes are distributed across your availability zones
- Each node is both a data node and master-eligible node
- Default index replica count of 1 ensures data redundancy
- Automatic shard allocation awareness based on zones

This architecture provides:
- No single point of failure
- Data redundancy across zones
- Continued operation if one zone fails
- Balanced resource utilization

## Multiple Instances

The chart supports deploying multiple separate Elasticsearch clusters (instances) if needed. For example:
- Setting `elasticInstances: 1` deploys a single 3-node Elasticsearch cluster
- Setting `elasticInstances: 2` deploys two separate 3-node Elasticsearch clusters

Each instance is a complete, independent Elasticsearch deployment with its own configuration.

## Parameters

The following table lists the configurable parameters of the Elasticsearch chart and their default values:

| Parameter                           | Description                                      | Default                           |
|------------------------------------|--------------------------------------------------|-----------------------------------|
| `elasticInstances`                 | Number of separate Elasticsearch deployments     | `1`                               |
| `elasticVersion`                   | Elasticsearch version to deploy                  | `8.17.0`                          |
| `storageSize`                      | Storage size for each Elasticsearch node         | `4Gi`                             |
| `storageClass`                     | Storage class for persistence                    | `managed-premium`                 |
| `nodeSelector.toleration`          | Toleration value for node placement              | `nil`                             |
| `azure`                            | Azure integration configuration (optional)        | `{}`                              |
| `azure.configEndpoint`             | Azure App Configuration endpoint                 | `nil`                             |
| `azure.storageAccountName`         | Azure Storage Account for snapshots             | `nil`                             |
| `azure.snapshots.containerName`    | Azure Storage Container for snapshots           | `es-snapshots`                    |
| `resources.requests.memory`        | Memory request for each ES node                 | `2Gi`                             |
| `resources.limits.memory`          | Memory limit for each ES node                   | `3Gi`                             |
| `resources.requests.cpu`           | CPU request for each ES node                    | `1`                               |
| `resources.limits.cpu`             | CPU limit for each ES node                      | `2`                               |

### Basic Installation

The chart will work with minimal configuration. For a basic installation:

```bash
helm install elasticsearch ./elastic-search
```

### Node Placement Configuration

To enable node placement and zone awareness, specify the toleration:

```yaml
nodeSelector:
  toleration: "cluster-paas"  # Enables node placement with this toleration value
```

### Azure-Integrated Installation

To enable Azure integration, provide the necessary Azure configuration:

```yaml
azure:
  storageAccountName: "elasticsnapshots"  # Required for Azure integration
  configEndpoint: "https://el-config.azconfig.io"  # Optional: for app configuration
  snapshots:  # Optional: defaults will be used if not specified
    containerName: "backups"  # Optional: defaults to "es-snapshots"
```

When Azure integration is enabled, you must also provide the following Kubernetes secrets:
- `elasticsearch-credentials`: Contains authentication credentials
  - `username-{i}`: Username for instance i
  - `password-{i}`: Password for instance i
  - `key-{i}`: Encryption key for instance i

### Resource Configuration Examples

1. For production use with higher resources:
```yaml
resources:
  requests:
    cpu: "4"
    memory: "8Gi"
  limits:
    cpu: "8"
    memory: "16Gi"
storageSize: "100Gi"
```

2. For multiple instances:
```yaml
elasticInstances: 2  # Deploys two separate clusters
```

3. To enable node placement with custom toleration:
```yaml
nodeSelector:
  toleration: "my-custom-toleration"
```