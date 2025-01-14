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

## Parameters

The following table lists the configurable parameters of the Elasticsearch chart and their default values:

| Parameter                           | Description                                      | Default                           |
|------------------------------------|--------------------------------------------------|-----------------------------------|
| `elasticInstances`                 | Number of Elasticsearch nodes                    | `1`                               |
| `elasticVersion`                   | Elasticsearch version to deploy                  | `8.17.0`                          |
| `storageSize`                      | Storage size for each Elasticsearch node         | `30Gi`                            |
| `storageClass`                     | Storage class for persistence                    | `managed-premium`                 |
| `azure.storageAccountName`         | Azure Storage Account for snapshots             | `""`                              |

## Configuration Examples

### Basic Configuration

A minimal `custom_values.yaml` for a single-node deployment:

```yaml
elasticVersion: "8.17.0"
storageSize: "30Gi"
storageClass: "managed-premium"
```

### Production Configuration

A recommended `custom_values.yaml` for production use with snapshots enabled:

```yaml
# Elasticsearch Version
elasticVersion: "8.17.0"

# Storage Configuration
storageSize: "100Gi"
storageClass: "managed-premium"

# Azure Integration
azure:
  storageAccountName: "elasticsnapshots"  # Your Azure storage account for snapshots

# Instance Configuration
elasticInstances: 1  # Number of separate Elasticsearch clusters
```

### Multi-Instance Configuration

Example `custom_values.yaml` for deploying multiple instances:

```yaml
# First Instance (custom_values_1.yaml)
elasticVersion: "8.17.0"
storageSize: "50Gi"
azure:
  storageAccountName: "elasticsnapshots1"

# Second Instance (custom_values_2.yaml)
elasticVersion: "8.17.0"
storageSize: "50Gi"
azure:
  storageAccountName: "elasticsnapshots2"
```

## Azure Blob Storage Integration

The chart automatically configures Azure Blob Storage for snapshots when `azure.storageAccountName` is provided. This includes:

1. Installing the `repository-azure` plugin
2. Configuring Azure authentication using Workload Identity
3. Setting up the necessary repository settings via JVM properties

### Prerequisites for Azure Integration

1. Create an Azure Storage Account
2. Configure Workload Identity:
   - Ensure the service account has the necessary roles assigned
   - Storage account should allow Workload Identity access

### Snapshot Repository Configuration

After deployment, create a snapshot repository:

```bash
PUT _snapshot/azure_repo
{
  "type": "azure",
  "settings": {
    "container": "snapshots"
  }
}
```

## Zone Awareness

The deployment is configured with zone awareness for high availability:

- Pods are distributed across availability zones using topology spread constraints
- Node attributes are automatically configured using zone labels
- Allocation awareness is enabled for optimal shard distribution

### Zone Configuration

The chart automatically:
- Uses node labels for zone awareness
- Configures topology spread constraints
- Sets up allocation awareness attributes

No additional configuration is needed for zone awareness as it uses the cluster's existing zone topology.

## Installing Multiple Instances

You can deploy multiple instances of Elasticsearch by using different value files:

```bash
# Deploy first instance
helm install elastic-1 ./elastic-search -f custom_values_1.yaml --namespace elastic-1 --create-namespace

# Deploy second instance
helm install elastic-2 ./elastic-search -f custom_values_2.yaml --namespace elastic-2 --create-namespace
```

## Maintenance

### Taking Snapshots

Once deployed with Azure Blob Storage configuration, you can create a snapshot repository:

```bash
PUT _snapshot/azure_repo
{
  "type": "azure",
  "settings": {
    "container": "snapshots"
  }
}
```

### Upgrading

To upgrade an existing release:

```bash
helm upgrade [RELEASE_NAME] ./elastic-search -f custom_values.yaml
```

## Uninstalling

To uninstall/delete a deployment:

```bash
helm uninstall [RELEASE_NAME] -n [NAMESPACE]
```

## Notes

- The chart uses init containers to install required plugins before starting Elasticsearch
- Azure authentication is handled through Workload Identity for enhanced security
- Memory mapping is disabled by default to avoid vm.max_map_count bootstrap check
- Zone awareness ensures high availability across availability zones

## Troubleshooting

Common issues and solutions:

1. **Plugin Installation Fails**
   - Verify network connectivity
   - Check Elasticsearch version compatibility

2. **Azure Storage Access Issues**
   - Verify Workload Identity configuration
   - Check storage account permissions
   - Ensure storage account name is correct

3. **Zone Distribution Issues**
   - Verify node labels for zones
   - Check if enough nodes are available in each zone
