@description('Required. Name of the key.')
param name string

@description('Required. Name of the value.')
param value string

@description('Optional. Name of the Label.')
param label string = ''

@description('Conditional. The name of the parent app configuration store. Required if the template is used in a standalone deployment.')
param appConfigurationName string

@description('Optional. The content type of the key-values value. Providing a proper content-type can enable transformations of values when they are retrieved by applications.')
param contentType string = ''

@description('Optional. Tags of the resource.')
param tags object = {}

resource appConfiguration 'Microsoft.AppConfiguration/configurationStores@2023-09-01-preview' existing = {
  name: appConfigurationName
}

var keyValueName = empty(label) ? name : '${name}$${label}'

resource keyValues 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-09-01-preview' = {
  name: keyValueName
  parent: appConfiguration
  properties: {
    contentType: contentType
    tags: tags
    value: value

  }
}
@description('The name of the key values.')
output name string = keyValues.name

@description('The resource ID of the key values.')
output resourceId string = keyValues.id

@description('The resource group the batch account was deployed into.')
output resourceGroupName string = resourceGroup().name
