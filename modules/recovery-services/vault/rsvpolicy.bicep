targetScope = 'subscription'
param location string = 'eastus2'

//vault policy name to be passed into the policy assignment resource

param customVaultPolicyName string = 'policyAssignmentRSV'

//declaring objects from json file for policy

param policy object = json(loadTextContent('./customVaultPolicy.json'))

//client code to be passed into the policy definition

param clientCode string = 'masvc'


//policy definition for recovery services vault

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name:'masvcRSVPolicyDefinition'
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

//policy assignment for recovery services vault

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
    displayName: 'AzMSP Recovery Services Vault Assignment'
  }
}

//remediation task for recovery services vault

resource remediatonTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'remediationTaskRSV'
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
