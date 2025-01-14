# Elasticsearch Helm Chart

This Helm chart deploys Elasticsearch and Kibana on Kubernetes using the Elastic Cloud on Kubernetes (ECK) operator. It supports various deployment configurations from single-node to highly available multi-node clusters.

## Features

- Flexible deployment options (1-3 nodes)
- Zone-aware node distribution
- Configurable resource allocation
- Azure integration support
- Automatic version management
- Kibana integration

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- ECK operator installed in the cluster
- For multi-zone deployments: Multiple node pools named z1pool, z2pool, z3pool

## Installation

```bash
helm install elastic ./charts/elastic-search
```

## Configuration

The following table lists the configurable parameters and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `elasticInstances` | Number of Elasticsearch instances to deploy | `1` |
| `elasticVersion` | Elasticsearch version (optional) | Chart's `appVersion` |
| `zones` | Number of zones/nodes (1-3) | `1` |
| `nodeSelector` | Node toleration value | `"cluster-paas"` |
| `resources.requests.cpu` | CPU request | `"1"` |
| `resources.requests.memory` | Memory request | `"2Gi"` |
| `resources.limits.cpu` | CPU limit | `"2"` |
| `resources.limits.memory` | Memory limit | `"3Gi"` |
| `storageSize` | Storage size for each node | `"4Gi"` |
| `storageClass` | Storage class | `"managed-premium"` |

### Zone Configuration

The chart supports three deployment modes:

1. **Single Node** (zones: 1)
   - Default configuration
   - All roles on one node
   - Suitable for development/testing

2. **Two Node** (zones: 2)
   - One master-eligible node (with data role)
   - One data-only node
   - Distributed across two zones
   - Not recommended for production

3. **Three Node** (zones: 3)
   - Three nodes with all roles
   - Distributed across three zones
   - Recommended for production
   - Full high availability

### Azure Integration

For Azure deployments, additional configuration is available:

```yaml
azure:
  configEndpoint: "https://el-config.azconfig.io"  # Azure App Configuration endpoint
  storageAccountName: "el-snapshots"               # Storage account for snapshots
  snapshots:
    containerName: "snapshots"                     # Container name for snapshots
```

## Examples

### Single Node Deployment

```yaml
elasticInstances: 1
zones: 1
```

### High Availability Deployment

```yaml
elasticInstances: 1
zones: 3
resources:
  requests:
    cpu: "2"
    memory: "4Gi"
  limits:
    cpu: "4"
    memory: "6Gi"
```

## Maintenance

### Version Updates

The Elasticsearch version can be controlled in two ways:
1. Via the chart's `appVersion` (default)
2. By setting `elasticVersion` in values.yaml (overrides default)

### Scaling

- Horizontal scaling is managed via the `elasticInstances` parameter
- Vertical scaling can be adjusted through the `resources` configuration

## Limitations

- Zone configuration cannot be changed after deployment
- Storage size cannot be reduced after deployment
- Kibana is always deployed on z2pool in multi-zone setups

## Troubleshooting

Common issues and solutions:

1. **Pods Pending**: Ensure node pools exist and have correct labels
2. **Cluster Not Forming**: Check network policies and node distribution
3. **Resource Issues**: Adjust resource requests/limits as needed