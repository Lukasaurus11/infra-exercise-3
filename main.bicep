param containerRegistryName string
param appServicePlanName string
param webAppName string
param containerRegistryImageName string
param containerRegistryImageVersion string
param location string
param keyVaultName string

param keyVaultSecretNameACRUsername string = 'acr-username'
param keyVaultSecretNameACRPassword1 string = 'acr-password1'

//key vault reference
resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
 }


// Azure Container Registry module
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
 }

// Azure Service Plan for Linux module
module servicePlan './ResourceModules-main/modules/web/serverfarm/main.bicep' = {
  name: appServicePlanName
  params: {
    name: appServicePlanName
    location: location
    sku: {
      capacity: 1
      family: 'B'
      name: 'B1'
      size: 'B1'
      tier: 'Basic'
    }
    reserved: true
  }
}

// Azure Web App for Linux containers module
module webApp './ResourceModules-main/modules/web/site/main.bicep' = {
  name: webAppName
  dependsOn: [
    servicePlan
    acr
    keyvault
  ]
  params: {
    name: webAppName
    location: location
    kind: 'app'
    serverFarmResourceId: servicePlan.outputs.resourceId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${containerRegistryImageName}:${containerRegistryImageVersion}'
      appCommandLine: ''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: false
    }
    dockerRegistryServerUrl: 'https://${containerRegistryName}.azurecr.io'
    dockerRegistryServerUserName: keyvault.getSecret(keyVaultSecretNameACRUsername)
    dockerRegistryServerPassword: keyvault.getSecret(keyVaultSecretNameACRPassword1)
  }
}

