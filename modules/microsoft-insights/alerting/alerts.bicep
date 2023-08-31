param location string
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

resource VMFreeSpaceRule 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
    name: 'Azure Virtual Machine Running Out of Disk Space'
    location: location
    tags: {
      environment: 'AzMSP'
    }
    properties: {
      displayName: 'Azure Virtual Machine Running Out of Disk Space'
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
        actionProperties: {}
      }
    }
  }
//adds memory utilization rule

resource VMMemUtilizationRule 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
    name: 'Azure Virtual Machine High Memory Utilization'
    location: location
    tags: {
      environment: 'AzMSP'
    }
    properties: {
      displayName: 'Azure Virtual Machine High Memory Utilization'
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
        actionProperties: {}
      }
    }
  }

//adds heartbeat metric rule

resource VMOffileRule 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
    name: 'Azure VM Is Offline'
    location: location
    tags: {
      environment: 'AzMSP'
    }
    properties: {
      displayName: 'Azure VM Is Offline'
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
        actionProperties: {}
      }
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
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
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
