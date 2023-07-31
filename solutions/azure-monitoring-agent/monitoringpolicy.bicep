//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'

//Parameters
param monitoringRG string = 'masvc-monitoringresources-rg' //this RG MUST Exist before this deployment is run. 

param clientCode string = 'masvc'

param policyInitiativeName string = 'Azure Monitoring Agent - AzMSP_Baseline'


//DCR Module
module dataCollectionRule 'dcr.bicep' = {
  name: 'datacollectionDeploy'
  scope: resourceGroup(monitoringRG)
  params: {
    clientCode: clientCode
  }
}



//Policy resource
resource policyInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: policyInitiativeName
  properties: {
    policyType: 'Custom'
    description: 'deploys azure monitoring agent to windows and linux VMs.'
    displayName: policyInitiativeName
    metadata: {
      category: 'AzMSP_Baseline'
    }
    policyDefinitions: [
    {
      policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/eab1f514-22e3-42e3-9a1f-e1dc9199355c'
      parameters: {
        dcrResourceId: {
          value: dataCollectionRule.outputs.resourceId
        }
        resourceType:{
          value: 'Microsoft.Insights/dataCollectionRules'
        }
      }
    }
    {
      policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/ca817e41-e85a-4783-bc7f-dc532d36235e'
      parameters: {}
    }
  ]
  }
}
