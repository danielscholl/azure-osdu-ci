# PostgreSQL Helm Chart

A Helm chart for deploying PostgreSQL clusters on Kubernetes using the CloudNativePG operator.

## Introduction

This chart deploys PostgreSQL database instances using the CloudNativePG operator. It supports both single-instance deployments for development and multi-instance clusters for production environments with high availability.

By default, if no databases are specified in the values file, the chart will create a single minimal database instance named `postgresql-db` with the following configuration:
```yaml
databases:
  - name: postgresql-db
    instances: 1
    storage:
      size: 4Gi  # Creates 2 x P1 disks (4Gi each)
```

You can override this default by specifying your own database configurations in the values file.

## Prerequisites

Before installing this chart, you must have:

1. Kubernetes Cluster Requirements:
   - Kubernetes 1.19+
   - Helm 3.0+
   - Storage class `managed-csi-premium` available

2. CloudNativePG Operator:
   - The operator must be installed and running in your cluster
   - You should see the deployment `database-operator-cloudnative-pg` running
   - The webhook service `cnpg-webhook-service` should be available

3. Optional Azure Requirements (if using Azure App Configuration):
   - Azure Workload Identity configured
   - Azure App Configuration instance

4. Optional Monitoring Requirements (if enabling monitoring):
   - Prometheus operator installed in the cluster
   - PodMonitor CRD available

## Installing the Chart

1. Create the required Kubernetes secrets:

```bash
# Create PostgreSQL superuser credentials
kubectl create secret generic postgresql-superuser-credentials \
  --namespace postgresql \
  --from-literal=username=postgres \
  --from-literal=password=<your-secure-password>

# Create PostgreSQL user credentials
kubectl create secret generic postgresql-user-credentials \
  --namespace postgresql \
  --from-literal=username=dbuser \
  --from-literal=password=<your-secure-password>
```

2. Install the chart:

```bash
helm install database ./charts/postgresql \
  --namespace postgresql \
  --create-namespace \
  --values custom_values.yaml
```

## Configuration

The following table lists the configurable parameters of the PostgreSQL chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `azure.configEndpoint` | Azure App Configuration endpoint URL (optional) | `nil` |

### Database Configuration

Each database in the `databases` list supports the following parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `name` | Name of the database cluster | Required |
| `instances` | Number of PostgreSQL instances | `1` |
| `syncReplicas` | Number of synchronous replicas (must be less than instances) | `0` |
| `resources.memory` | Memory request/limit for each instance | `nil` |
| `resources.cpu` | CPU request/limit for each instance | `nil` |
| `affinity.agentPools` | List of Kubernetes node pools to schedule on | `nil` |
| `affinity.toleration` | Toleration value for node scheduling | `nil` |
| `monitoring` | Enable Prometheus monitoring via PodMonitor | `false` |
| `storage.size` | Size of the main data volume (minimum 4Gi) | `4Gi` |
| `storage.walSize` | Size of the WAL volume (optional, minimum 4Gi) | `20% of storage.size` |

## Values File Examples

### Minimal Configuration (Development)

```yaml
databases:
  - name: simple-db
    instances: 1
```

### Production Configuration (High Availability)

```yaml
# Optional: Azure App Configuration integration
azure:
  configEndpoint: "https://<your-appconfig>.azconfig.io"

databases:
  - name: cluster-db
    instances: 3
    syncReplicas: 1
    resources:
      memory: 2Gi
      cpu: 1
    affinity:
      agentPools: ["z1pool", "z2pool", "z3pool"]
      toleration: "cluster-paas"
    monitoring: true
    storage:
      size: 10Gi
      walSize: 5Gi
```

## Generated Resources

For each database defined in the values file, the following resources are created:

1. PostgreSQL Instances:
   - Primary pod and optional replica pods based on `instances` count
   - Each pod includes WAL (Write-Ahead Log) storage

2. Kubernetes Services:
   - `<db-name>-rw`: Read/Write service (points to primary)
   - `<db-name>-ro`: Read-Only service (load balances across all instances)
   - `<db-name>-r`: All replicas service

3. Storage:
   - Main Storage: 2Gi per instance (managed-csi-premium)
   - WAL Storage: 2Gi per instance (managed-csi-premium)

4. Optional Resources:
   - AzureAppConfigurationProvider (if azure.configEndpoint is provided)
   - PodMonitor for Prometheus integration (if monitoring is enabled)

## High Availability

When deploying with multiple instances (`instances > 1`):
- Synchronous replication is configured via `syncReplicas`
- Pod anti-affinity ensures pods are distributed across zones
- Topology spread constraints are enabled for zone distribution
- Multiple services are created for different access patterns

## Azure Integration (Optional)

The chart can optionally integrate with Azure services:

1. Azure App Configuration:
   - Enabled by providing `azure.configEndpoint`
   - Used for dynamic configuration management
   - Creates an AzureAppConfigurationProvider resource
   - Requires Azure Workload Identity configuration

## Monitoring (Optional)

The chart supports Prometheus monitoring through PodMonitor resources:

1. Enable monitoring for a database:
   ```yaml
   databases:
     - name: mydb
       monitoring: true
   ```

2. Requirements:
   - Prometheus operator installed in the cluster
   - PodMonitor CRD available

3. Metrics available:
   - PostgreSQL instance metrics
   - WAL metrics
   - Replication metrics
   - Connection metrics

## Limitations

- Storage size is fixed at 2Gi for both main and WAL storage
- Requires CloudNativePG operator to be pre-installed
- Azure Workload Identity required if using Azure App Configuration
- Single instance deployments do not provide high availability
- Monitoring requires Prometheus operator

## Troubleshooting

Common issues and solutions:

1. Pods stuck in Pending state:
   - Verify node pool labels match affinity settings
   - Check if required tolerations are configured
   - Ensure storage class exists

2. Database initialization fails:
   - Verify secrets exist and are correctly formatted
   - Check Azure Workload Identity configuration (if using Azure App Configuration)
   - Review pod logs for specific errors

3. Replication issues:
   - Ensure `syncReplicas` is less than total instances
   - Check network connectivity between pods
   - Verify WAL storage is properly configured

4. Monitoring issues:
   - Verify Prometheus operator is running
   - Check PodMonitor CRD exists
   - Review Prometheus target discovery logs

## Uninstalling the Chart

To uninstall/delete the deployment:

```bash
helm uninstall database -n postgresql
```

All resources including PVCs will be automatically cleaned up.

## Support

For support, please open an issue in the GitHub repository.

## Storage Configuration

Each database instance requires two storage volumes using Azure Premium Storage. For simplicity, both volumes (main storage and WAL) use the same size configuration.

### Azure Premium Storage Requirements

- Each instance requires two separate managed disks (main storage and WAL)
- Both disks use the same size configuration
- Minimum size is 4GiB (P1 tier) per disk
- Storage requests are automatically rounded up to the nearest tier

### Azure Premium Storage Tiers
The chart automatically rounds up storage requests to the nearest valid tier:

| Tier | Size | IOPS | Throughput | Typical Use |
|------|------|------|------------|-------------|
| P1   | 4 GiB  | 120  | 25 MB/s   | Minimum viable (dev/test) |
| P2   | 8 GiB  | 400  | 19 MB/s   | Small workloads |
| P3   | 16 GiB | 500  | 60 MB/s   | Testing environments |
| P4   | 32 GiB | 2300 | 120 MB/s  | Production workloads |
| P6   | 64 GiB | 4500 | 150 MB/s  | High-performance needs |

> **Important**:
> - Each instance gets TWO disks of the specified size (one for main storage, one for WAL)
> - Both disks will be the same size as specified in `storage.size`
> - Minimum size is 4GiB (P1 tier) per disk

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storage.size` | Size for both main and WAL volumes | `4Gi` |

The specified size will be used for both:
1. Main Storage (Data files)
2. WAL Storage (Write-Ahead Log files)

Example configurations:

```yaml
# Development environment (minimum configuration)
databases:
  - name: dev-db
    instances: 1
    storage:
      size: 4Gi    # Creates 2 x P1 disks (4Gi each)

# Production environment (high performance)
databases:
  - name: prod-db
    instances: 3
    storage:
      size: 32Gi   # Creates 2 x P4 disks (32Gi each) per instance
```

### Cost Considerations

When planning your storage, remember:
1. Each instance gets TWO disks of the specified size
2. Minimum configuration (4Gi) means:
   - Single instance: 2 × 4GiB = 8GiB total
   - Three instances: 6 × 4GiB = 24GiB total
3. Production configuration (32Gi) means:
   - Single instance: 2 × 32GiB = 64GiB total
   - Three instances: 6 × 32GiB = 192GiB total

### Performance Considerations

1. For development/testing:
   - Use P1 (4GiB) - 120 IOPS, 25 MB/s per disk
   - Total IOPS per instance: 240 IOPS
   - Total throughput per instance: 50 MB/s

2. For production:
   - Use P4 (32GiB) or larger - 2300 IOPS, 120 MB/s per disk
   - Total IOPS per instance: 4600 IOPS
   - Total throughput per instance: 240 MB/s
