@description('Location for resources')
param location string = resourceGroup().location

@description('Name of the Cognitive Services / Azure OpenAI resource (must be globally unique within Azure)')
param openAIName string

@description('SKU to use for the Cognitive Services account (default: S0)')
param skuName string = 'S0'

@description('Whether public network access is Enabled or Disabled')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Optional tags')
param tags object = {}

// Minimal Cognitive Services account (OpenAI) resource
resource openai 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: openAIName
  location: location
  kind: 'OpenAI'
  sku: {
    name: skuName
  }
  properties: {
    // Keep properties minimal and secure. Disable local auth by default.
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: true
  }
  tags: tags
}

output cognitiveServiceResourceId string = openai.id
output cognitiveServiceName string = openai.name
output cognitiveServiceLocation string = openai.location
