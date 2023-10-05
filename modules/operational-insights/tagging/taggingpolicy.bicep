//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'
param location string

param customTagPolicyName string

//declaring objects from json file for policy
param policy object = json(loadTextContent('./customTagPolicy.json'))

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'ResourceTaggingDefinition'
  properties:{
    displayName: policy.properties.displayName
    policyType: policy.properties.policyType
    description: policy.properties.description
    metadata: policy.properties.metadata
    policyRule: policy.policyRule
  }
}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: customTagPolicyName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/masvc-monitoringresources-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/masvcpolicyuami' :{}
    }
  }
  properties: {
    policyDefinitionId: policyDefinition.id
    displayName: 'AzMSP Resource Tagging Assignment'
  }
}


resource remediatonTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'ResourceTaggingRemediationTask'
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
