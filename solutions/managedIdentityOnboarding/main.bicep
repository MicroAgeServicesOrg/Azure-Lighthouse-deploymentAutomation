//set scope
targetScope = 'subscription'


//Parameters

@description('Location for all resources.')
param location string = 'westus3'



resource masvcUAMIRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'masvc-uami-rg'
  location: location
}


module policyUAMIDeployment '../../modules/carml/managed-identity/user-assigned-identity/main.bicep' = {
  name: 'policyUAMIDeployment'
  scope: masvcUAMIRG
  params: {
    location: location
    name: 'masvcpolicyuami'
    tags: {
      MicroAge_AzMSP: 'enabled'
    }
  }

}

module policyUAMIAssignment '../../modules/carml/role-assignment/subscription/main.bicep' = {
  name: 'policyUAMIAssignment'
  params: {
    location: location
    principalId: policyUAMIDeployment.outputs.principalId
    roleDefinitionIdOrName: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalType: 'ServicePrincipal'
    subscriptionId: subscription().subscriptionId
    delegatedManagedIdentityResourceId: policyUAMIDeployment.outputs.resourceId
  }
}
