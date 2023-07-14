param location string = 'eastus2'
param clientCode string
param queries object = json(loadTextContent('./alerts.json'))


//gets existing workspace via client code entered manually and inputs this into scope
resource existingWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name:'${clientCode}-centralWorkspace'
}

//adds the action group resouce before the alert rules itself
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'masvc-emails'
  location: 'global'
  tags:{
    environment: 'AzMSP'
  }
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
  tags:{
    environment: 'AzMSP'
  }
  properties: {
    displayName: 'Azure Backup Job Failed'
    severity: 2
    enabled: true
    evaluationFrequency: 'P1D'
    scopes: [
      existingWorkspace.id
    ]
    windowSize: 'P1D'
    criteria: {
      allOf: [
        {
          query: queries.backupJobFailedQuery
          timeAggregation: 'Total'
          metricMeasureColumn: 'Count'
          dimensions: [
            {
              name: 'JobStatus'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
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
  name: 'Azure Site Recovery "Critical" Health'
  location: location
  tags:{
    environment: 'AzMSP'
  }
  properties: {
    displayName: 'Azure Site Recovery "Critical" Health'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT30M'
    scopes: [
      existingWorkspace.id
    ]
    windowSize: 'PT30M'
    criteria: {
      allOf: [
        {
          query: queries.asrCriticalHealthQuery
          timeAggregation: 'Total'
          metricMeasureColumn: 'count_'
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
    muteActionsDuration: 'P1D'
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
  tags:{
    environment: 'AzMSP'
  }
  properties: {
    displayName: 'Azure Site Recovery \'RPO\' Exceeds 30 Minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT30M'
    scopes: [
      existingWorkspace.id
    ]
    windowSize: 'PT30M'
    criteria: {
      allOf: [
        {
          query: queries.asrRPOExceeds30Query
          timeAggregation: 'Total'
          metricMeasureColumn: 'count_'
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
    ruleResolveConfiguration:{
      autoResolved: true
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
      actionProperties: {}
    }
  }
}

//adds free space metric rule

resource metricVMFreeSpaceRule 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'Azure Virtual Machine is Almost Out of Hard Drive Space'
  location: 'global'
  tags: {
    environment: 'AzMSP'
  }
  properties: {
    description: 'This Alert is triggered when used space exceeds 95%'
    severity: 2
    enabled: true
    scopes: [
      existingWorkspace.id
    ]
    evaluationFrequency: 'PT15M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          threshold: 90
          name: 'Metric1'
          metricNamespace: 'Microsoft.OperationalInsights/workspaces'
          metricName: 'Average_% Used Space'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.OperationalInsights/workspaces'
    targetResourceRegion: 'eastus2'
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
      }
    ]
  }
}

//adds memory utilization rule

resource metricVMUtilizationRule 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'Azure Virtual Machine High Memory Utilization'
  location: 'global'
  tags: {
    environment: 'AzMSP'
  }
  properties: {
    description: 'This alert rule fires when a VM uses over 80% memory for over 15 minutes'
    severity: 2
    enabled: true
    scopes: [
      existingWorkspace.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          threshold: 80
          name: 'Metric1'
          metricNamespace: 'Microsoft.OperationalInsights/workspaces'
          metricName: 'Average_% Used Memory'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.OperationalInsights/workspaces'
    targetResourceRegion: 'eastus2'
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
      }
    ]
  }
}

//adds heartbeat metric rule

resource metricVMOffileRule'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'Azure VM Is Offline'
  location: 'global'
  properties: {
    description: 'This alert fires if a VM in Azure goes offline for longer than 5 minutes'
    severity: 0
    enabled: true
    scopes: [
      existingWorkspace.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      allOf: [
        {
          threshold: 0
          name: 'Metric1'
          metricNamespace: 'Microsoft.OperationalInsights/workspaces'
          metricName: 'Heartbeat'
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [
                '*'
              ]
            }
            {
              name: 'OSType'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'LessThanOrEqual'
          timeAggregation: 'Total'
          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.OperationalInsights/workspaces'
    targetResourceRegion: 'eastus2'
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
      }
    ]
  }
}

//adds cpu percentage rule

resource metricVMCpuRule 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'Azure VM CPU Percentage Over 75 Percent'
  location: 'global'
  tags: {
    environment: 'AzMSP'
  }
  properties: {
    description: 'Azure VM CPU percentage is over 75%'
    severity: 2
    enabled: true
    scopes: [
      existingWorkspace.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          threshold: 75
          name: 'Metric1'
          metricNamespace: 'Microsoft.OperationalInsights/workspaces'
          metricName: 'Average_% Processor Time'
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.OperationalInsights/workspaces'
    targetResourceRegion: 'eastus2'
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
      }
    ]
  }
}
