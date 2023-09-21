metadata name = 'Recovery Services Vaults'
metadata description = 'This module deploys a Recovery Services Vault.'


@description('Optional. Location for all resources.')
param location string
@description('Optional. Client Identifier.')
param clientCode string

@description('Required. Name of the Azure Recovery Service Vault.')
param vaultName string = '${clientCode}-${location}-vmRSV'


@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}



var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null




resource rsv 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: vaultName
  location: location
  identity: identity
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
  }
}
