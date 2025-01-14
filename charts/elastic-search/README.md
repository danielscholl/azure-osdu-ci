# Elasticsearch Helm Chart

This Helm chart deploys Elasticsearch instances on Kubernetes with support for multiple deployments.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- ECK Operator 2.16.0+ installed in the cluster
- Azure Workload Identity configured for Azure Blob Storage access

## Features

- Zone awareness for high availability
- Azure Blob Storage integration for snapshots
- Automatic plugin installation
- Workload Identity integration for secure Azure authentication

## High Availability Architecture

Each Elasticsearch instance is configured for high availability by default:

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

Each instance is a complete, independent Elasticsearch deployment with its own high availability configuration.

## Parameters

The following table lists the configurable parameters of the Elasticsearch chart and their default values. All parameters are optional and will use their defaults if not specified:

| Parameter                           | Description                                      | Default                           |
|------------------------------------|--------------------------------------------------|-----------------------------------|
| `elasticInstances`                 | Number of separate Elasticsearch deployments     | `1`                               |
| `elasticVersion`                   | Elasticsearch version to deploy                  | `8.17.0`                          |
| `storageSize`                      | Storage size for each Elasticsearch node         | `4Gi` (minimum for managed-premium)|
| `storageClass`                     | Storage class for persistence                    | `managed-premium`                 |
| `azure.snapshots.storageAccountName`| Azure Storage Account for snapshots             | `el-snapshots`                    |
| `azure.snapshots.containerName`    | Azure Storage Container for snapshots           | `snapshots`                       |
| `resources.requests.memory`        | Memory request for each ES node                 | `2Gi`                             |
| `resources.limits.memory`          | Memory limit for each ES node                   | `2Gi`                             |

> Note: All parameters have built-in defaults defined in values.yaml. You only need to create a `custom_values.yaml` file if you want to override any of these defaults.

### Built-in Features

The following features are built into the chart and managed by the ECK operator:

1. **TLS Security**: TLS is enabled by default with self-signed certificates managed by ECK
2. **Network Ports**: Standard Elasticsearch ports (9200 for HTTP, 9300 for transport) are configured automatically
3. **Zone Awareness**: Automatic zone distribution for high availability
4. **Azure Integration**: Azure blob storage support via the repository-azure plugin

### Default Configuration

The chart will work with an empty `custom_values.yaml` file or even without one. All necessary defaults are built into the chart in values.yaml.

For example, this is a valid deployment that will use all the default values:
```bash
helm install elasticsearch ./elastic-search
```

### Override Examples

If you want to customize the deployment, you can override specific values. For example:

1. To change storage size for production use:
```yaml
storageSize: "100Gi"  # Recommended for production
```

2. To use a different Azure storage account:
```yaml
azure:
  snapshots:
    storageAccountName: "elasticsnapshots"
    containerName: "mybackups"
```

3. To deploy multiple Elasticsearch clusters:
```yaml
elasticInstances: 2  # Will deploy two separate 3-node ES clusters
```

4. To set resource limits and requests for production use:
```yaml
resources:
  requests:
    cpu: "2"      # Added CPU request (no default)
    memory: "4Gi" # Increased from default 2Gi
  limits:
    cpu: "4"      # Added CPU limit (no default)
    memory: "8Gi" # Increased from default 2Gi
```