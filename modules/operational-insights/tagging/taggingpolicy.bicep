//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'

param customTagPolicyName string

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01'

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: customTagPolicyName
}
