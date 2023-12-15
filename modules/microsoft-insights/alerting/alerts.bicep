param location string
param clientCode string
param queries object = json(loadTextContent('./customAlerts.json'))


//gets existing workspace via client code entered manually and inputs this into scope
resource existingWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name:'${clientCode}-centralWorkspace'
}

//adds the action group resouce before the alert rules itself
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'masvc-connectwise'
  location: 'global'
  tags:{
    MicroAge_AzMSP: 'enabled'
  }
  properties: {
    groupShortName: 'masvc-cw'
    enabled: true
    webhookReceivers: [
      {
        name: 'masvc-cwlogicapp'
        serviceUri: 'https://prod-83.eastus.logic.azure.com:443/workflows/c199cd5f60f042d9b9692f5e77e181bf/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=hjJlQPSFduj8GeVmJfFpyZjdo9X8e4RjpbGm4Cx4Ra4'
        useAadAuth: false
        useCommonAlertSchema: true
      }
    ]
  }
}

//adds azure backup job failed rule
resource azbackupJobFailedRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'Azure Backup Job Failed'
  location: location
  tags:{
    MicroAge_AzMSP: 'enabled'
  }
  identity: {
    type: 'SystemAssigned'
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
          resourceIdColumn: 'ResourceId'
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
    MicroAge_AzMSP: 'enabled'
  }
  identity: {
    type: 'SystemAssigned'
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
    MicroAge_AzMSP: 'enabled'
  }
  identity: {
    type: 'SystemAssigned'
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

resource VMFreeSpaceRule 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: 'Windows Virtual Machine Running Out of Disk Space'
  location: location
  tags:{
    MicroAge_AzMSP: 'enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Windows Virtual Machine Running Out of Disk Space'
    description: 'Alerts when disk space is below 10 percent.'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      existingWorkspace.id
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    windowSize: 'PT15M'
    overrideQueryTimeRange: 'P2D'
    criteria: {
      allOf: [
        {
          query: queries.VMFreeSpaceQuery
          timeAggregation: 'Average'
          metricMeasureColumn: 'CounterValue'
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          resourceIdColumn: '_ResourceId'
          operator: 'LessThanOrEqual'
          threshold: 10
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
    }
  }
}

resource LinuxVMFreeSpaceRule 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: 'Linux Virtual Machine Running Out of Disk Space'
  location: location
  tags:{
    MicroAge_AzMSP: 'enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Linux Virtual Machine Running Out of Disk Space'
    description: 'Alerts when disk space is below 15 GB.'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      existingWorkspace.id
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    windowSize: 'PT15M'
    overrideQueryTimeRange: 'P2D'
    criteria: {
      allOf: [
        {
          query: queries.LinuxVMFreeSpaceQuery
          timeAggregation: 'Average'
          metricMeasureColumn: 'FreeGB'
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          resourceIdColumn: '_ResourceId'
          operator: 'LessThanOrEqual'
          threshold: 15
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
    }
  }
}


  //creates memory utilization rule
resource VMMemUtilizationRule 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: 'Azure Virtual Machine High Memory Utilization'
  location: location
  tags:{
    MicroAge_AzMSP: 'enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'This alert triggers when a machine is over 85 percent utilization for longer than 5 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      existingWorkspace.id
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: queries.VMMemUtilizationQuery
          timeAggregation: 'Average'
          metricMeasureColumn: 'MemoryUtilization'
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          resourceIdColumn: '_ResourceId'
          operator: 'GreaterThan'
          threshold: 85
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
    }
  }
}

//adds heartbeat metric rule

resource VMOffileRule 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: 'Azure VM Is Offline'
  location: location
  tags:{
    MicroAge_AzMSP: 'enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'Alerts when a VM has been off longer than 15 mins'
    severity: 0
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      existingWorkspace.id
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    windowSize: 'PT15M'
    overrideQueryTimeRange: 'P2D'
    criteria: {
      allOf: [
        {
          query: queries.VMOfflineQuery
          timeAggregation: 'Average'
          metricMeasureColumn: 'HeartbeatCount'
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'LessThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
    }
  }
}

  //creates cpu percentage rule

resource metricVMCpuRule 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'Azure VM CPU Percentage Over 75 Percent'
  location: 'global'
  tags:{
    MicroAge_AzMSP: 'enabled'
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
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
      }
    ]
  }
}
