param location string = 'westus2'

param vmName string = 'wu2-testvm01'

param vmRgName string = 'masvc-wu2-test-rg'

param clientCode string = 'masvc'


var backupFabric = 'Azure'
var backupPolicy = 'azMSPVMBackupPolicy'
var v2VMType = 'Microsoft.Compute/virtualMachines'
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

resource vaultPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = {
  name: backupPolicy
  location: location
  parent: vault
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
          retentionTimes: [
            '2024-02-21T22:00:00Z'
          ]
        }
        monthlySchedule: {
          retentionDuration: {
            count: 12
            durationType: 'Months'
          }
          retentionScheduleFormatType: 'Weekly'
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '2024-02-21T22:00:00Z'
          ]
        }
        retentionPolicyType: 'LongTermRetentionPolicy'
        weeklySchedule: {
          daysOfTheWeek: [
            'Sunday'
          ]
          retentionDuration: {
            count: 4
            durationType: 'Weeks'
          }
          retentionTimes: [
            '2024-02-21T22:00:00Z'
          ]
        }
        yearlySchedule: {
          monthsOfYear: [
            'January'
          ]
          retentionDuration: {
            count: 3
            durationType: 'Years'
          }
          retentionScheduleFormatType: 'Weekly'
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '2024-02-21T22:00:00Z'
          ]
        }
      }
      schedulePolicy: {
        schedulePolicyType: 'SimpleSchedulePolicyV2'
        dailySchedule: {
          scheduleRunTimes: [
            '2024-02-21T22:00:00Z'
          ]
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
