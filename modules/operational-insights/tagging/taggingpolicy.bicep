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
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: policyDefinition.id
    displayName: 'AzMSP Resource Tagging Assignment'
  }
}

resource ContributorAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, 'azMSPTaggingPolicy', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
    principalId: policyAssignment.identity.principalId
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
