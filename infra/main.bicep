// Starter Bicep to provision storage + function app (Linux, Python 3.11) for the RewritePirate function
@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Function App (must be globally unique within resource group)')
param functionAppName string

@description('Storage account name (must be globally unique, lowercase)')
param storageAccountName string

@description('SKU for plan - use "Y1" for Consumption (Dynamic)')
param skuName string = 'Y1'

// Create storage account
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// App Service plan (Consumption)
resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${functionAppName}-plan'
  location: location
  sku: {
    name: skuName
    tier: (skuName == 'Y1') ? 'Dynamic' : 'ElasticPremium'
  }
  kind: 'functionapp'
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, '2021-04-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
      ]
    }
    httpsOnly: true
  }
  // resource dependencies are inferred; no explicit dependsOn required
}

output functionEndpoint string = 'https://${functionApp.name}.azurewebsites.net'
output storageAccountName string = storage.name
