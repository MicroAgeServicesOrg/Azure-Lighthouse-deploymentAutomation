//Parameters

@description('site recovery vault name')

param siteRecoveryName string

@description('log analytics workspace ID')

param logAnalyticsWorkspaceId string

@description('log analytics workspace name')

param logAnalyticsWorkspaceName string

param dashboardName string

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

//Modules

module asrDashboard 'br:masvcbicep.azurecr.io/bicep/modules/azuresiterecovery/dashboard:05-30-2023' = {
  name: 'ASRDashboard'
  params: {
    location: resourceGroup().location
    dashboardName: dashboardName
    logAnalyticsName: logAnalyticsWorkspaceName
  }

}

output siteRecoveryId string = siteRecovery.id
