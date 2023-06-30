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
