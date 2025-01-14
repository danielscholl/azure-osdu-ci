param AksName string

param PoolName string

@description('The zones to use for a node pool')
param availabilityZones array = []

@description('OS disk type')
param osDiskType string = 'Managed'

@description('VM SKU')
param agentVMSize string = 'Standard_DS3_v2'

@description('Disk size in GB')
param osDiskSizeGB int = 0

@description('The number of agents for the user node pool')
param agentCount int = 3

@description('The maximum number of nodes for the user node pool')
param agentCountMax int = 0
var autoScale = agentCountMax > agentCount

@description('The maximum number of pods per node.')
param maxPods int = 30

@description('Any taints that should be applied to the node pool')
param nodeTaints array = []

@description('Any labels that should be applied to the node pool')
param nodeLabels object = {}

@description('OS Type for the node pool')
@allowed([
  'Linux'
  'Windows'
])
param osType string = 'Linux'

resource aks 'Microsoft.ContainerService/managedClusters@2024-04-02-preview' existing = {
  name: AksName
}

resource nodepool 'Microsoft.ContainerService/managedClusters/agentPools@2024-04-02-preview' = {
  parent: aks
  name: PoolName
  properties: {
    mode: 'User'
    vmSize: agentVMSize
    count: agentCount
    minCount: autoScale ? agentCount : null
    maxCount: autoScale ? agentCountMax : null
    enableAutoScaling: autoScale
    availabilityZones: !empty(availabilityZones) ? availabilityZones : null
    osDiskType: osDiskType
    osDiskSizeGB: osDiskSizeGB
    osType: osType
    osSKU: osType == 'Linux' ? 'AzureLinux' : null
    maxPods: maxPods
    type: 'VirtualMachineScaleSets'

    upgradeSettings: {
      maxSurge: '33%'
    }
    nodeTaints: nodeTaints
    nodeLabels: nodeLabels
  }
}
