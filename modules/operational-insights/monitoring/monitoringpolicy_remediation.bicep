
@description('Policy Definition Resource ID to create remediation task for.')
param remediatePolicyId string
@description('The Policy Definitions that were applied')
param policyDefinitions array
@description('The Policy Assignment ID')
param policyAssignmentId string

resource remediateTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = [for definition in policyDefinitions: if (remediatePolicyId == definition.policyDefinitionId) {
  name: guid('Remediate', definition.policyDefinitionReferenceId, subscription().id)
  properties: {
    failureThreshold: {
      percentage: 1
    }
    resourceCount: 500
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceId: definition.policyDefinitionReferenceId
    parallelDeployments: 10
    resourceDiscoveryMode: 'ExistingNonCompliant'
  }
}] 
