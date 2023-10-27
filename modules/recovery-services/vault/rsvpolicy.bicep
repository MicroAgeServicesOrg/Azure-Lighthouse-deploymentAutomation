targetScope = 'subscription'
param location string = 'eastus2'

param customVaultPolicyName string = 'AzMSP Vault Policy'

param policy object = json(loadTextContent('./customVaultPolicy.json'))

param clientCode string = 'masvc'




resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name:'VaultPolicyDefinition'
  properties: {
    displayName: policy.properties.displayName
    policyType: policy.properties.policyType
    description: policy.properties.description
    metadata: policy.properties.metadata
    policyRule: policy.properties.policyRule
    parameters : {
      clientCode: {
        type: 'String'
        defaultValue: clientCode
      }
      effect: policy.properties.parameters.effect
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
    displayName: 'AzMSP Backup Vault Assignment'
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