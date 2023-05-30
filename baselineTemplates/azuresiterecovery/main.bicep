//Parameters

@description('site recovery vault name')

param siteRecoveryName string

@description('log analytics workspace ID')

param logAnalyticsWorkspaceId string

@description('log analytics workspace name')

param logAnalyticsWorkspaceName string

//Resources...soon to go into Modules

resource siteRecovery 'Microsoft.RecoveryServices/vaults@2022-02-01' = {
  name: siteRecoveryName
  location: resourceGroup().location
  properties: {
    diagnostics: {
      enabled: true
      workspaceId: logAnalyticsWorkspaceId
      workspaceName: logAnalyticsWorkspaceName
      logs: [
        {
          category: 'AzureSiteRecoveryJobs'
          enabled: true
          retentionPolicy: {
            enabled: false
          }
        }
        {
          category: 'AzureSiteRecoveryEvents'
          enabled: true
          retentionPolicy: {
            enabled: false
          }
        }
        {
          category: 'AzureSiteRecoveryReplicatedItems'
          enabled: true
          retentionPolicy: {
            enabled: false
          }
        }
        {
          category: 'AzureSiteRecoveryReplicationStats'
          enabled: true
          retentionPolicy: {
            enabled: false
          }
        }
        {
          category: 'AzureSiteRecoveryRecoveryPoints'
          enabled: true
          retentionPolicy: {
            enabled: false
          }
        }
        {
          category: 'AzureSiteRecoveryReplicationDataUploadRate'
          enabled: true
          retentionPolicy: {
            enabled: false
          }
        }
        {
          category: 'AzureSiteRecoveryProtectedDiskChurn'
          enabled: true
          retentionPOlicy: {
            enabled: false
          }
        }
     ]
    }
  }
}

output siteRecoveryId string = siteRecovery.id
