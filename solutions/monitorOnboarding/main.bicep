targetScope = 'subscription'

//global params
param location string = 'westus3'
param clientCode string

//dcrParams
param dataCollectionRuleName string = 'masvcMonitoringDCR'

//monitoringPolicyParams
param policyInitiativeName string = 'AzMSP_Baseline - Azure Monitoring'


//param to define the custom policy definition for the DCR policy.
param dcrPolicy object = json(loadTextContent('../../customPolicyDefinitions/dcrPolicy.json'))

//param to define the custom policy definition for the MMA policy.
param amaPolicy object = json(loadTextContent('../../customPolicyDefinitions/amaWindowsPolicy.json'))

//param for user assigned identity for policy assignment.
param userAssignedIdentityId string = '/subscriptions/${subscription().subscriptionId}/resourceGroups/masvc-uami-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/masvcpolicyuami'




// Deploy the base resource group for all resources within this deployment. 
resource monitoringRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'masvc-monitoringresources-rg'
  location: location
}

//deploy the log analytics workspace used for monitoring services. 
module deployLogAnalytics '../../modules/operational-insights/workspaces/loganalytics.bicep' = {
  name: 'deployLogAnalytics'
  scope: monitoringRG
  params: {
    location: location
    clientcode: clientCode
}
}
//deploy the data collection rule for the monitoring agent.
module dataCollectionRule '../../modules/operational-insights/monitoring/dcr.bicep' = {
  name: 'deployDCR'
  scope: monitoringRG
  params: {
    clientCode: clientCode
    location: location
    dataCollectionRuleName: dataCollectionRuleName

  }
  dependsOn: [
    deployLogAnalytics
  ]
}

//CARML Module for the DCR Policy. This policy is custom, hence we need to create it first. It will be added to the initiative below. 
module customDCRPolicyDefinitionCARML '../../modules/carml/policy-definition/subscription/main.bicep' = {
  name: 'createCustomPolicyForDCR'
  params: {
    location: location
    name: 'masvcDCRPolicyDefinition'
    displayName: dcrPolicy.properties.displayName
    description: dcrPolicy.properties.description
    metadata: dcrPolicy.properties.metadata
    parameters: dcrPolicy.properties.parameters
    policyRule: dcrPolicy.properties.policyRule
  }
}

//CARML Module for the AMA Policy. This policy is custom, hence we need to create it first. It will be added to the initiative below. 
module customAMAPolicyDefinitionCARML '../../modules/carml/policy-definition/subscription/main.bicep' = {
  name: 'createCustomPolicyForAMA'
  params: {
    location: location
    name: 'masvcAMAPolicyDefinition'
    displayName: amaPolicy.properties.displayName
    description: amaPolicy.properties.description
    metadata: amaPolicy.properties.metadata
    parameters: amaPolicy.properties.parameters
    policyRule: amaPolicy.properties.policyRule
  }
}



//CARML Module for the PolicyDefinition (Initiative). This joins microsoft default policies with the custom policy above and deploys them. 
module monitoringPolicyInitiativeCARML '../../modules/carml/policy-set-definition/subscription/main.bicep' = {
  name: 'deployMonitoringInitiativeCARML'
  params: {
    name: policyInitiativeName
    location: location
    policyDefinitions: [
      {
        policyDefinitionId: customDCRPolicyDefinitionCARML.outputs.resourceId
        policyDefinitionReferenceId: customDCRPolicyDefinitionCARML.outputs.resourceId
        parameters: {
          dcrResourceId: {
            value:dataCollectionRule.outputs.resourceId
          }
          resourceType: {
            value: 'Microsoft.Insights/dataCollectionRules'
          }
          scopeToSupportedImages: {
            value: bool('false')
          }
        }
      }
      {
        policyDefinitionId: customAMAPolicyDefinitionCARML.outputs.resourceId
        policyDefinitionReferenceId: customAMAPolicyDefinitionCARML.outputs.resourceId
        parameters: {
          scopeToSupportedImages:{
            value: bool('false')
          }
        }
      }
    ]
    
  }
  dependsOn: [
    customAMAPolicyDefinitionCARML
    customDCRPolicyDefinitionCARML
  ]
}


//deploy custom alerts from the alerts folder. 
module deployAlerting '../../modules/microsoft-insights/alerting/alerts.bicep' = {
  name: 'deployAlerts'
  scope: monitoringRG
  params:{
    clientCode: clientCode
    location: location
  }
  dependsOn: [
    deployLogAnalytics
    dataCollectionRule
  ]
}

//policy Assignment for AMA
module policyAssignmentMonitoringInit '../../modules/carml/policy-assignment/subscription/main.bicep' = {
  name: '${uniqueString(deployment().name)}-policyAssignmentAMA'
  params: {
    name: 'policyAssignmentAMA'
    location: location
    enforcementMode: 'Default'
    policyDefinitionId: monitoringPolicyInitiativeCARML.outputs.resourceId
    identity: 'UserAssigned'
    userAssignedIdentityId: userAssignedIdentityId
  }

}

//deploy the remediaton task for the AMA policy.
module remediationTaskAMA '../../modules/carml/policy-insights/remediation/subscription/main.bicep' = {
  name: '${uniqueString(deployment().name)}-remediationTaskAMA'
  params: {
    name: 'remediationTaskAMA'
    location: location
    policyAssignmentId: policyAssignmentMonitoringInit.outputs.resourceId
    policyDefinitionReferenceId: customAMAPolicyDefinitionCARML.outputs.resourceId
    resourceDiscoveryMode: 'ReEvaluateCompliance'
    failureThresholdPercentage: '0.5'
  }
}


//deploy the remediaton task for the DCR policy.
module remediationTaskDCR '../../modules/carml/policy-insights/remediation/subscription/main.bicep' = {
  name: '${uniqueString(deployment().name)}-remediationTaskDCR'
  params: {
    name: 'remediationTaskDCR'
    location: location
    policyAssignmentId: policyAssignmentMonitoringInit.outputs.resourceId
    policyDefinitionReferenceId: customDCRPolicyDefinitionCARML.outputs.resourceId
    resourceDiscoveryMode: 'ReEvaluateCompliance'
    failureThresholdPercentage: '0.5'
  }
}
