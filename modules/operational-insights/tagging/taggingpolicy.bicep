//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'

param customTagPolicyName string

//declaring objects from json file for policy
param policy object = json(loadTextContent('./customTagPolicy.json'))

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'ResourceTagging'
  properties:{
    displayName: policy.policyDefinition.properties.displayName
    policyType: policy.policyDefinition.properties.policyType
    description: policy.policyDefinition.properties.description
    metadata: policy.policyDefinition.properties.metadata
    policyRule: policy.policyDefinition.properties.policyRule
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
