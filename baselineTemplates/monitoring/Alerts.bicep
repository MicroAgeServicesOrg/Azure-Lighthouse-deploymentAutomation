param location string = 'eastus2'
param workspaceResourceId string


//adds the action grouup resouce before the alert rule itself
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'masvc-emails'
  location: location
  properties: {
    groupShortName: 'masvc-emails'
    enabled: true
    emailReceivers: [
      {
        name: 'to-support'
        emailAddress: 'masalerts@microage.com'
      }
    ]
  }
}


resource scheduledQueryRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'Azure Backup Job Failed'
  location: location
  properties: {
    displayName: 'Azure Backup Job Failed'
    severity: 2
    enabled: true
    evaluationFrequency: 'P1D'
    scopes: [
      workspaceResourceId
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    windowSize: 'P1D'
    criteria: {
      allOf: [
        {
          query: 'AddonAzureBackupJobs\n| where JobOperation == "Backup" \n| where JobStatus == "Failed"\n| extend FailedJobDetails = strcat("Backup Item: ", BackupItemFriendlyName, ", Management Type: ", BackupManagementType, ", Time Generated: ", TimeGenerated)\n| summarize Count = count(), FailedJobs = make_list(FailedJobDetails) by JobStatus\n\n'
          timeAggregation: 'Total'
          metricMeasureColumn: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
      actionProperties: {}
    }
  }
}
