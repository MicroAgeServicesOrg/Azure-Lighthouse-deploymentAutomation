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

param clientCode string = 'masvc'




resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name:'VaultPolicyDefinition'
  properties: {
    displayName: policy.properties.displayName
    policyType: policy.properties.policyType
    description: policy.properties.description
    metadata: policy.properties.metadata
    policyRule: policy.properties.policyRule
    parameters: policy.properties.parameters
    parameters : {
      clientCode: {
        type: 'String'
        defaultValue: clientCode
      }
      vmName: policy.properties.parameters.vmName
      vmRgName: policy.properties.parameters.vmRgName
      location: policy.properties.parameters.location
    }
  }
}


resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: customVaultPolicyName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/masvc-uami-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/masvcpolicyuami': {}
    }
  }
  properties: {
    policyDefinitionId: policyDefinition.id
    displayName: 'AzMSP Test Backup Vault'
  }
}

resource remediatonTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'RecoveryServicesVaultRemediationTask'
  properties: {
    policyAssignmentId: policyAssignment.id
    resourceDiscoveryMode: 'ExistingNonCompliant'
    parallelDeployments: 10
    failureThreshold: {
      percentage: 1
    }
    filters: {
      locations: []
    }
    resourceCount: 500
}
}
