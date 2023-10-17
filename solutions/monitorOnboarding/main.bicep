targetScope = 'subscription'

//global params
param location string = 'westus3'
param clientCode string

//dcrParams
param dataCollectionRuleName string = 'masvcMonitoringDCR'

//monitoringPolicyParams
param policyInitiativeName string = 'Azure Monitoring Agent - AzMSP_Baseline'

param customTagPolicyName string = 'Azure Resource Tagging - AzMSP_Baseline'



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
//deploy the custom tagging policy as defined for this deployment.
module customTagPolicy '../../modules/operational-insights/tagging/taggingpolicy.bicep' = {
  name: 'deployTagPolicy'
  params: {
    customTagPolicyName: customTagPolicyName
    location: location
  }
}

module monitoringPolicy '../../modules/operational-insights/monitoring/monitoringpolicy.bicep' = {
  name: 'deployMonitoringPolicy'
  params: {
    location: location
    policyInitiativeName: policyInitiativeName
    dcrResourceID: dataCollectionRule.outputs.resourceId
    
  }
  dependsOn: [
    deployLogAnalytics
  ]
}

module deployAlerting '../../modules/microsoft-insights/alerting/alerts.bicep' = {
  name: 'deployAlerts'
  scope: monitoringRG
  params:{
    clientCode: clientCode
    location: location
  }
  dependsOn: [
    deployLogAnalytics
  ]
}


