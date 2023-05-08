//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'

//Parameters

@description('Optional. Location for all resources.')
param location string



//Resources

resource backupRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${location}-centralrsv-rg'
  location: location
}


//Modules

module backupVault 'br:masvcbicep.azurecr.io/bicep/modules/backup:05-08-2023' = {
  name: 'backupVaultDeployment'
  scope: backupRG
  params: {
    clientPrefix: 'masvc'
  }
}
