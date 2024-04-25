//Rebuilding the backup deployment as of Mar 28th 2024
//This version will utilize AVM Modules where possible, and remove the need to deploy vaults with policy
//Instead the policy will control resource > vault association and bicep will deploy our standard resources. 
targetScope = 'subscription'
param location string = 'westus3'
param clientCode string
param subscriptionId string = subscription().subscriptionId
param vaultPolicy object = json(loadTextContent('../../customPolicyDefinitions/customVaultPolicyRevamped.json'))

param vmBackupPolicyName string = 'azmspBackupPolicyVM'


var vaultName = '${clientCode}-${location}-centralVault'


var masvcBackupRGName = 'masvc-${location}-backupresources-rg'

var vmBackupPolicyID = '/subscriptions/${subscriptionId}/resourceGroups/${masvcBackupRGName}/providers/Microsoft.RecoveryServices/vaults/${vaultName}/backupPolicies/${vmBackupPolicyName}'

//create resource group to house backupResources
resource masvcVMBackupRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: masvcBackupRGName
  location: location
}


//create central vault
module centralVaultVM 'br/public:avm/res/recovery-services/vault:0.2.0' = {
  name: 'recoveryServicesVault'
  scope: masvcVMBackupRG
  params: {
    name: vaultName
    location: location
    backupStorageConfig: {
      crossRegionRestoreFlag: false
      storageModelType: 'GeoRedundant'
    }
    backupPolicies: [
      {
        name: vmBackupPolicyName
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
  }
}


//Deploy Policies to associate resources with our central vault

//policy definition for recovery services vault
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name:'masvcRSVPolicyDefinition-${location}'
  properties: {
    displayName: '${vaultPolicy.properties.displayName} - ${location}'
    policyType: vaultPolicy.properties.policyType
    description: vaultPolicy.properties.description
    metadata: vaultPolicy.properties.metadata
    policyRule: vaultPolicy.properties.policyRule
    parameters : {
      vaultLocation: {
        type: 'String'
        defaultValue: location
      }
      backupPolicyId: {
        type: 'String'
        defaultValue: vmBackupPolicyID
      }
      exclusionTagName: {
        type: 'String'
        defaultValue: 'ExcludeFromBackup'
      }
      exclusionTagValue: {
        type: 'Array'
        defaultValue: ['true']
      }
      effect: vaultPolicy.properties.parameters.effect
    }
  }
}


//policy assignment for recovery services vault
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'masvcRSVPolicyAssignment-${location}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/masvc-uami-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/masvcpolicyuami': {}
    }
  }
  properties: {
    policyDefinitionId: policyDefinition.id
    displayName: 'AzMSP Recovery Services Vault Assignment - ${location}'
  }
}
