//set scope
targetScope = 'subscription'


//Parameters

@description('Location for all resources.')
param location string = 'westus3'



resource masvcUAMIRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'masvc-uami-rg'
  location: location
}


module policyUAMIDeployment 'br:masvcbicepcentralmodules.azurecr.io/bicep/modules/managed-identity.user-assigned-identity:0.4.0' = {
  name: 'policyUAMIDeployment'
  scope: masvcUAMIRG
  params: {
    location: location
    name: 'masvcpolicyuami'
    tags: {
      owner: 'masvc'
    }
  }

}

module policyUAMIAssignment 'br:masvcbicepcentralmodules.azurecr.io/bicep/modules/authorization.role-assignment.subscription:0.4.0' = {
  name: 'policyUAMIAssignment'
  params: {
    principalId: policyUAMIDeployment.outputs.principalId
    roleDefinitionIdOrName: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalType: 'ServicePrincipal'
    subscriptionId: subscription().subscriptionId
    delegatedManagedIdentityResourceId: policyUAMIDeployment.outputs.resourceId
  }

}
