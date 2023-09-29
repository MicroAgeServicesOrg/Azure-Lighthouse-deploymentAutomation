//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'
param location string

//Parameters
param policyInitiativeName string

param dcrResourceID string




//declaring objects from json file for policy
param policy object = json(loadTextContent('./dcrPolicy.json'))

//building custom DCR Policy
resource dcrPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'customDCRPolicyDefinition'
  properties:{
    displayName: policy.properties.displayName
    policyType: policy.properties.policyType
    description: policy.properties.description
    metadata: policy.properties.metadata
    policyRule: policy.properties.policyRule
    parameters: policy.properties.parameters
  }
}




//Policy initative resource
resource policyInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: policyInitiativeName
  properties: {
    policyType: 'Custom'
    description: 'deploys azure monitoring agent and DCR to windows VMs.'
    displayName: policyInitiativeName
    metadata: {
      category: 'AzMSP_Baseline'
    }
    policyDefinitions: [
    {
      policyDefinitionId: dcrPolicyDefinition.id
      policyDefinitionReferenceId: dcrPolicyDefinition.id
      parameters: {
        dcrResourceId: {
          value: dcrResourceID
        }
        resourceType:{
          value: 'Microsoft.Insights/dataCollectionRules'
        }
        scopeToSupportedImages:{
          value: bool('false')
        }
      }
    }
    {
      policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/ca817e41-e85a-4783-bc7f-dc532d36235e'
      policyDefinitionReferenceId: '/providers/Microsoft.Authorization/policyDefinitions/ca817e41-e85a-4783-bc7f-dc532d36235e'
      parameters: {
        scopeToSupportedImages:{
          value: bool('false')
        }
      }
    }
  ]
  }
}


resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyInitiativeName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'AzMSP Monitoring Initiative assignment'
    enforcementMode: 'Default'
    policyDefinitionId: policyInitiative.id

  }
}

resource ContributorAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, 'azMSPMonitoringPolicy', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalType: 'ServicePrincipal'
    principalId: policyAssignment.identity.principalId
  }
}

resource dcrRemediatonTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'dcrRemediationTask'
  scope: policyAssignment
  properties: {
    parallelDeployments: 10
    failureThreshold: {
      percentage: 0
    }
    filters: {
      locations: []
    }
    resourceCount: 500
    policyAssignmentId: policyAssignment.id
    policyDefinitionReferenceId: dcrPolicyDefinition.id
    resourceDiscoveryMode: 'ExistingNonCompliant'
}
dependsOn: [
  policyInitiative
]

}
resource remediatonTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'monitoringAgentRemediationTask'
  scope: policyAssignment
  properties: {
    parallelDeployments: 10
    failureThreshold: {
      percentage: 0
    }
    filters: {
      locations: []
    }
    resourceCount: 500
    policyAssignmentId: policyAssignment.id
    policyDefinitionReferenceId: '/providers/Microsoft.Authorization/policyDefinitions/ca817e41-e85a-4783-bc7f-dc532d36235e'
    resourceDiscoveryMode: 'ExistingNonCompliant'
}
}
