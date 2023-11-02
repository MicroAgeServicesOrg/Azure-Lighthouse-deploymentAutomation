//maintenance configuration for azure update manager
//https://docs.microsoft.com/en-us/azure/automation/update-management/overview

param location string

resource maintenanceConfig 'Microsoft.Maintenance/maintenanceConfigurations@2023-04-01' = {
  name: 'MicroAge AzMSP Patching Schedule'
  location: location
  tags: {
    MicroAge_AzMSP: 'enabled'
  }
  properties: {
    extensionProperties: {
      InGuestPatchMode: 'User'
    }
    installPatches: {
      linuxParameters: {
        classificationsToInclude: []
        packageNameMasksToExclude: []
        packageNameMasksToInclude: []
      }
      rebootSetting: 'IfRequired'
      windowsParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
        ]
        kbNumbersToExclude: []
        kbNumbersToInclude: []
      }
    }
    maintenanceScope: 'InGuestPatch'
    maintenanceWindow: {
      duration: '03:00'
      expirationDateTime: '9999-12-31 23:59:59'
      recurEvery: 'Month Last Sunday'
      startDateTime: '2022-12-31 08:00'
      timeZone: 'UTC'
    }
    namespace: 'masvc'
    visibility: 'Custom'
  }
}


@description('The resource ID of the Maintenance Configuration.')
output maintenanceConfigId string = maintenanceConfig.id
