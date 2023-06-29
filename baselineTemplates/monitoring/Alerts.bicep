param location string = 'eastus2'
param workspaceResourceId string


//adds the action grouup resouce before the alert rule itself
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'masvc-emails'
  location: 'global'
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

//adds azure backup job failed rule
resource azbackupJobFailedRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
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

//adds ASR Critical health rule

resource asrCriticalRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'Azure Site Recovery \'Critical\' Health'
  location: location
  properties: {
    displayName: 'Azure Site Recovery \'Critical\' Health'
    severity: 1
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
          query: 'AzureDiagnostics\\r\\n\\| where replicationProviderName_s == \\"InMageRcm\\"\\r\\n\\| where replicationHealth_s == \\"Critical\\"\\r\\n\\| where isnotempty(name_s) and isnotnull(name_s)\\r\\n\\| summarize hint.strategy=partitioned arg_max(TimeGenerated, *)\\r\\nby name_s\\r\\n\\| summarize count()'
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

//adds asr rpo health over 30 minutes rule
resource asrRPORule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'Azure Site Recovery \'RPO\' Exceeds 30 Minutes'
  location: location
  properties: {
    displayName: 'Azure Site Recovery \'RPO\' Exceeds 30 Minutes'
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
          query: 'AzureDiagnostics\\r\\n\\| where replicationProviderName_s == \\"InMageRcm\\"\\r\\n\\| where rpoInSeconds_d > 1800\\r\\n\\| summarize count()'
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
