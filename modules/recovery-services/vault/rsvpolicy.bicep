targetScope = 'subscription'
param location string = 'eastus2'

param customVaultPolicyName string = 'AzMSP Vault Policy'

param policy object = json(loadTextContent('./customVaultPolicy.json'))

//@description('Optional. Location for all resources.')
//param location string
//@description('Optional. Client Identifier.')
//param clientCode string

//@description('Required. Name of the Azure Recovery Service Vault.')
//param vaultName string = '${clientCode}-${location}-vmRSV'




resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name:'VaultPolicyDefinition'
  properties: {
    displayName: policy.properties.displayName
    policyType: policy.properties.policyType
    description: policy.properties.description
    metadata: policy.properties.metadata
    policyRule: policy.policyRule
  }
}


resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: customVaultPolicyName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/masvc-uami-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/masvcpolicyuami' :{}
    }
  }
  properties: {
    policyDefinitionId: policyDefinition.id
    displayName: 'AzMSP Test Backup Vault'
  }
}

