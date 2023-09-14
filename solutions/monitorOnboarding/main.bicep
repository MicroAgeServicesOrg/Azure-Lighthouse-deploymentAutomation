targetScope = 'subscription'

//global params
param location string = 'westus3'
param clientCode string

//dcrParams
param dataCollectionRuleName string = 'masvcMonitoringDCR'

//monitoringPolicyParams
param policyInitiativeName string = 'Azure Monitoring Agent - AzMSP_Baseline'

param customTagPolicyName string = 'Azure Resource Tagging - AzMSP_Baseline'




resource monitoringRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'masvc-monitoringresources-rg'
  location: location
}



module deployLogAnalytics '../../modules/operational-insights/workspaces/loganalytics.bicep' = {
  name: 'deployLogAnalytics'
  scope: monitoringRG
  params: {
    location: location
    clientcode: clientCode
}
}

module dataCollectionRule '../../modules/operational-insights/monitoring/dcr.bicep' = {
  name: 'deployDCR'
  scope: monitoringRG
  params: {
    clientCode: clientCode
    location: location
    dataCollectionRuleName: dataCollectionRuleName

  }
}

module customTagPolicy '../../modules/operational-insights/tagging/taggingpolicy.bicep' = {
  name: 'deployTagPolicy'
  params: {
    customTagPolicyName: customTagPolicyName
  }
}

module monitoringPolicy '../../modules/operational-insights/monitoring/monitoringpolicy.bicep' = {
  name: 'deployMonitoringPolicy'
  params: {
    policyInitiativeName: policyInitiativeName
    dcrResourceID: dataCollectionRule.outputs.resourceId
    
  }
}

module deployAlerting '../../modules/microsoft-insights/alerting/alerts.bicep' = {
  name: 'deployAlerts'
  scope: monitoringRG
  params:{
    clientCode: clientCode
    location: location
  }
}

module remediationTasks '../../modules/operational-insights/monitoring/monitoringpolicy_remediation.bicep' = {
  name: 'remediationTasks'
  scope: monitoringRG
  params: {
    policyAssignmentId: monitoringPolicy.outputs.policyAssignmentID
    policyDefinitions: [
      monitoringPolicy
    ]
    remediatePolicyId:monitoringPolicy.outputs.policyDefinitionID
  }
}

