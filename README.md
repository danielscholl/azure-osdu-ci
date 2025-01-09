# OSDU Community Implementation - Azure

This project demonstrates a way to run the [OSDU Community Implementation](https://gitlab.opengroup.org/osdu/pmc/community-implementation/-/tree/main) native to Azure while using concepts from the [OSDU Developer](https://github.com/azure/osdu-developer) project.


## Register the feature flags

To use AKS Automatic in preview, you must register feature flags for other required features. Register the following flags using the [az feature register](https://learn.microsoft.com/en-us/cli/azure/feature?view=azure-cli-latest#az-feature-register) command.

```bash
az feature register --namespace Microsoft.ContainerService --name EnableAPIServerVnetIntegrationPreview
az feature register --namespace Microsoft.ContainerService --name NRGLockdownPreview
az feature register --namespace Microsoft.ContainerService --name SafeguardsPreview
az feature register --namespace Microsoft.ContainerService --name NodeAutoProvisioningPreview
az feature register --namespace Microsoft.ContainerService --name DisableSSHPreview
az feature register --namespace Microsoft.ContainerService --name AutomaticSKUPreview
```

Verify the registration status by using the [az feature show](https://learn.microsoft.com/en-us/cli/azure/feature?view=azure-cli-latest#az-feature-show) command. It takes a few minutes for the status to show *Registered*:

```bash
az feature show --namespace Microsoft.ContainerService --name AutomaticSKUPreview
```

### CLI Quickstart

```bash
# Authenticate
az login --scope https://graph.microsoft.com//.default
az account set --subscription <your_subscription_id>
azd auth login

# Prepare
azd init -e ci

# Provisioning
azd provision

# Cleanup
azd down --force --purge
```