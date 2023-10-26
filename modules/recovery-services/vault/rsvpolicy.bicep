targetScope = 'subscription'
metadata name = 'Recovery Services Vaults'
metadata description = 'This module deploys a Recovery Services Vault.'


//@description('Optional. Location for all resources.')
//param location string
//@description('Optional. Client Identifier.')
//param clientCode string

//@description('Required. Name of the Azure Recovery Service Vault.')
//param vaultName string = '${clientCode}-${location}-vmRSV'




resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2020-09-01' = {
  name: 'TESTBackupVaultDef' // Unique name for the policy definition
  properties: {
    displayName: 'Example Policy Definition'
    policyRule: json(loadTextContent('./customVaultPolicy.json'))
  }
}


resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: 'TESTBackupVault' // Unique name for the policy assignment
  properties: {
    displayName: 'AzMSP Test Backup Vault'
    policyDefinitionId: policyDefinition.id
    parameters: {
      // If your policy definition has parameters, you can specify them here
    }
  }
}

