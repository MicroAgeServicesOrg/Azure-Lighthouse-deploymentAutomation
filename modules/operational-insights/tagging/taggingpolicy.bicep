//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'

param customTagPolicyName string

//declaring objects from json file for policy
param policy object = json(loadTextContent('./customTagPolicy.json'))

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'ResourceTagging'
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
  location: 'westus2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/masvc-lighthouseuami-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/microagelighthouseuami' :{}
    }
  }
  properties: {
    enforcementMode: 'Default'
    policyDefinitionId: policyDefinition.id
  }
}

resource remediatonTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'ResourceTaggingRemediationTask'
  properties: {
    policyAssignmentId: policyAssignment.id
    policyDefinitionReferenceId: policyDefinition.id
}
}
