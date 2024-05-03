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
