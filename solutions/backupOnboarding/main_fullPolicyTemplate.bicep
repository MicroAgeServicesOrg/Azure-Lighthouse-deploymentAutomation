// This file is the deployment file for the baseline azMSP recovery services vault and vault policies. 
//This file is only used to convert to json for policy deployment. it is not deployed directly. 

targetScope = 'subscription'

param location string

param clientCode string

param vmName string

param vmRgName string


param backupPolicies array = [
  {
    name: 'azmspBackupPolicyVM'
    properties: {
      backupManagementType: 'AzureIaasVM'
      policyType: 'V2'
      instantRPDetails: {}
      instantRpRetentionRangeInDays: 2
      protectedItemsCount: 0
      retentionPolicy: {
        dailySchedule: {
          retentionDuration: {
            count: 14
            durationType: 'Days'
          }
          retentionTimes: [
            '2019-11-07T22:00:00Z'
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
            '2019-11-07T22:00:00Z'
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
            '2019-11-07T22:00:00Z'
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
            '2019-11-07T22:00:00Z'
          ]
        }
      }
      schedulePolicy: {
        schedulePolicyType: 'SimpleSchedulePolicyV2'
        dailySchedule: {
          scheduleRunTimes: ['2019-11-07T22:00:00Z']
        }
        scheduleRunFrequency: 'Daily'
      }
      tieringPolicy: {
        ArchivedRP: {
          tieringMode: 'TierRecommended'
          duration: 0
          durationType: 'Invalid'
        }
      }
      timeZone: 'Pacific Standard Time'
    }
  }
  {
    name: 'azmspBackupPolicySQL'
    properties: {
      backupManagementType: 'AzureWorkload'
      protectedItemsCount: 0
      settings: {
        isCompression: true
        issqlcompression: true
        timeZone: 'Pacific Standard Time'
      }
      subProtectionPolicy: [
        {
          policyType: 'Full'
          retentionPolicy: {
            monthlySchedule: {
              retentionDuration: {
                count: 60
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
                '2019-11-07T22:00:00Z'
              ]
            }
            retentionPolicyType: 'LongTermRetentionPolicy'
            weeklySchedule: {
              daysOfTheWeek: [
                'Sunday'
              ]
              retentionDuration: {
                count: 104
                durationType: 'Weeks'
              }
              retentionTimes: [
                '2019-11-07T22:00:00Z'
              ]
            }
            yearlySchedule: {
              monthsOfYear: [
                'January'
              ]
              retentionDuration: {
                count: 10
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
                '2019-11-07T22:00:00Z'
              ]
            }
          }
          schedulePolicy: {
            schedulePolicyType: 'SimpleSchedulePolicy'
            scheduleRunDays: [
              'Sunday'
            ]
            scheduleRunFrequency: 'Weekly'
            scheduleRunTimes: [
              '2019-11-07T22:00:00Z'
            ]
            scheduleWeeklyFrequency: 0
          }
        }
        {
          policyType: 'Differential'
          retentionPolicy: {
            retentionDuration: {
              count: 30
              durationType: 'Days'
            }
            retentionPolicyType: 'SimpleRetentionPolicy'
          }
          schedulePolicy: {
            schedulePolicyType: 'SimpleSchedulePolicy'
            scheduleRunDays: [
              'Monday'
            ]
            scheduleRunFrequency: 'Weekly'
            scheduleRunTimes: [
              '2017-03-07T02:00:00Z'
            ]
            scheduleWeeklyFrequency: 0
          }
        }
        {
          policyType: 'Log'
          retentionPolicy: {
            retentionDuration: {
              count: 15
              durationType: 'Days'
            }
            retentionPolicyType: 'SimpleRetentionPolicy'
          }
          schedulePolicy: {
            scheduleFrequencyInMins: 120
            schedulePolicyType: 'LogSchedulePolicy'
          }
        }
      ]
      workLoadType: 'SQLDataBase'
    }
  }
  {
    name: 'azmspBackupPolicyFiles'
    properties: {
      backupManagementType: 'AzureStorage'
      protectedItemsCount: 0
      retentionPolicy: {
        dailySchedule: {
          retentionDuration: {
            count: 30
            durationType: 'Days'
          }
          retentionTimes: [
            '2019-11-07T04:30:00Z'
          ]
        }
        retentionPolicyType: 'LongTermRetentionPolicy'
      }
      schedulePolicy: {
        schedulePolicyType: 'SimpleSchedulePolicy'
        scheduleRunFrequency: 'Daily'
        scheduleRunTimes: [
          '2019-11-07T04:30:00Z'
        ]
        scheduleWeeklyFrequency: 0
      }
      timeZone: 'Pacific Standard Time'
      workloadType: 'AzureFileShare'
    }
  }
]


//varaibles
var vaultName = '${clientCode}-${location}-centralVault'

var masvcBackupRGName = 'masvc-${location}-backupresources-rg'



//create resource group to house backupResources
resource masvcVMBackupRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: masvcBackupRGName
  location: location
}


//deploy recovery services vault module
module rsvDeployment '../../modules/customModules/recoveryServices/recoveryServicesVault.bicep' = {
  name: 'deploy-RSV'
  scope: masvcVMBackupRG
  params: {
    location: location
    vaultName: vaultName
    backupPolicies: backupPolicies
    vmName: vmName
    vmRgName: vmRgName
  }
}


