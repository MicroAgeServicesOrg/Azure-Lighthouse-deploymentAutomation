@description('Location for VM and Backup vault')
param location string

@description('Name of VM to be backed up')
param vmName string

@description('Name of Resource Group for VM')
param vmRgName string

@description(
  'Clients short code goes here, this helps name resources deployed by this template'
)
param clientCode string

var backupFabric = 'Azure'
var backupPolicy = 'azMSPVMBackupPolicy'
var v2VmType = 'Microsoft.Compute/virtualMachines'
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'
var vaultName = take('${clientCode}-${location}-centralVault', 50)

resource vault 'Microsoft.RecoveryServices/vaults@2023-06-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource vaultName_backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = {
  parent: vault
  name: '${backupPolicy}'
  location: location
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    instantRPDetails: {}
    instantRpRetentionRangeInDays: 2
    protectedItemsCount: 0
    retentionPolicy: {
      dailySchedule: {
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
        retentionTimes: ['2024-02-21T22:00:00Z']
      }
      monthlySchedule: {
        retentionDuration: {
          count: 12
          durationType: 'Months'
        }
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: ['Sunday']
          weeksOfTheMonth: ['First']
        }
        retentionTimes: ['2024-02-21T22:00:00Z']
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
      weeklySchedule: {
        daysOfTheWeek: ['Sunday']
        retentionDuration: {
          count: 4
          durationType: 'Weeks'
        }
        retentionTimes: ['2024-02-21T22:00:00Z']
      }
      yearlySchedule: {
        monthsOfYear: ['January']
        retentionDuration: {
          count: 3
          durationType: 'Years'
        }
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: ['Sunday']
          weeksOfTheMonth: ['First']
        }
        retentionTimes: ['2024-02-21T22:00:00Z']
      }
    }
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      dailySchedule: {
        scheduleRunTimes: ['2024-02-21T22:00:00Z']
      }
      scheduleRunFrequency: 'Daily'
    }
    tieringPolicy: {
      ArchivedRP: {
        tieringMode: 'TierRecommended'
      }
    }
    timeZone: 'Pacific Standard Time'
  }
}

resource vaultName_backupFabric_v2VmContainer_vmRgName_vmName_v2Vm_vmRGName_vm 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-01-01' = {
  name: '${vaultName}/${backupFabric}/${v2VmContainer}${vmRgName};${vmName}/${v2Vm}${vmRgName};${vmName}'
  location: location
  properties: {
    protectedItemType: v2VmType
    policyId: vaultName_backupPolicy.id
    sourceResourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vmRgName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
  }
  dependsOn: [vault]
}

output status string = 'Backup enabled successfully for VM: ${vmName}Backup Vault: ${vaultName}'
