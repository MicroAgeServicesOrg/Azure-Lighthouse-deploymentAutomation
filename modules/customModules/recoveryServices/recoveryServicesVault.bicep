//Rebuilding the backup deployment as of Mar 28th 2024
//This is the module responsible for deploying the vault, storage config, and policies. 

@description('location for resource deployment')
param location string

@description('Required. Name of resovery services vault')
param vaultName string

@description('Required. Name of resource group that the VM resides in')
param vmRgName string

@description('Name of the VM being backed up')
param vmName string

@description('Required. properties of the backup policy')
param backupPolicies array = []

//variables
var backupFabric = 'Azure'
var v2VmType = 'Microsoft.Compute/virtualMachines'
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'

@description('The scope of resources for which the alert processing rule will apply. You can leave this field unchanged if you wish to apply the rule for all Recovery Services vault within the subscription. If you wish to apply the rule on smaller scopes, you can specify an array of ARM URLs representing the scopes, eg. [\'/subscriptions/<sub-id>/resourceGroups/RG1\', \'/subscriptions/<sub-id>/resourceGroups/RG2\']')
param alertProcessingRuleScope array = [
  resourceGroup().id
]



//create the recovery services vault
resource rsv 'Microsoft.RecoveryServices/vaults@2023-01-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

//create the RSV Storage Config
resource rsvBackupStorageConfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2023-01-01' = {
  name: 'vaultstorageconfig'
  parent: rsv
  properties: {
    crossRegionRestoreFlag: false
    storageModelType: 'GeoRedundant'
  }
}

//create the backup Policies
resource rsvBackupPolicyConfig 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-01-01' = [for backupPolicy in backupPolicies: {
  name: backupPolicy.name
  parent: rsv
  properties: backupPolicy.properties
}]

//create the protected item (vm) for backup
resource protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-01-01' = {
  name: '${vaultName}/${backupFabric}/${v2VmContainer}${vmRgName};${vmName}/${v2Vm}${vmRgName};${vmName}'
  location: location
  properties: {
    protectedItemType: v2VmType
    policyId: rsvBackupPolicyConfig[0].id
    sourceResourceId: resourceId(subscription().subscriptionId, vmRgName, 'Microsoft.Compute/virtualMachines', '${vmName}')

  }
}

//create the action group for alerts
resource actionGroupCW 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'masvc-connectwise-backups'
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

//alert processing rule 
resource alertProcessingRule 'Microsoft.AlertsManagement/actionRules@2021-08-08' = {
  name: 'AlertProcessingRule-${resourceGroup().name}'
  location: 'global'
  properties: {
    scopes: alertProcessingRuleScope
    conditions: [
      {
      field: 'TargetResourceType'
      operator: 'Equals'
      values: [
        'microsoft.recoveryservices/vaults'
      ]
      }
    ]
    description: 'Recovery Services Alert Processing Rule'
    enabled: true
    actions: [
      {
        actionGroupIds: [
          actionGroupCW.id
        ]
        actionType: 'AddActionGroups'
      }
    ]
  }
}
