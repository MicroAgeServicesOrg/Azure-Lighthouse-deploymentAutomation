targetScope = 'subscription'
param location string = 'eastus2'

//paramter for resource group name

resource existingRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name:'masvc-monitoringresources-rg'
}

//declaring objects from json file for policy

param policy object = json(loadTextContent('./customUpdatePolicy.json'))

//client code to be passed into the policy definition

//param clientCode string = 'masvc'

//module for maintenance config

module maintenanceConfig '../../../modules/microsoft-maintenance/patching/patchingpolicy.bicep' = {
  name: 'deployMaintenanceConfig'
  scope: existingRG
  params: {
    location: location
  }
}

//policy definition for recovery services vault

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name:'masvcPatchingPolicyDefinition'
  properties: {
    displayName: policy.properties.displayName
    policyType: policy.properties.policyType
    description: policy.properties.description
    metadata: policy.properties.metadata
    policyRule: policy.properties.policyRule
    parameters: policy.properties.parameters
  }
}

//policy assignment for recovery services vault

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'policyAssignmentPatching'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/masvc-uami-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/masvcpolicyuami': {}
    }
  }
  properties: {
    policyDefinitionId: policyDefinition.id
    displayName: 'AzMSP Patching Management'
  }
}

//remediation task for recovery services vault

resource remediatonTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'remediationTaskPatching'
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
