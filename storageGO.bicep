@description('Specifies the name of the Azure Storage account.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Specifies the prefix of the file share names.')
param sharePrefix string = 'storage'

@description('Specifies the location in which the Azure Storage resources should be deployed.')
param location string = resourceGroup().location

@description('List of file shares to create in the storage account')
param shareNames array = ['default']

resource sa 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
  }
}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = [for share in shareNames : {
  name: '${sa.name}/default/${sharePrefix}${share}'
}]

output storageAccountName string = storageAccountName
