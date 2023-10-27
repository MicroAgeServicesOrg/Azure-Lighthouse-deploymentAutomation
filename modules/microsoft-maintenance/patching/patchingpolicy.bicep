param location string

//maintenance configuration for azure update manager

resource maintenanceConfig 'Microsoft.Maintenance/maintenanceConfigurations@2023-04-01' = {
  name: 'MicroAge AzMSP Patching Schedule'
  location: location
  tags: {
    MicroAge_AzMSP: 'enabled'
  }
  properties: {
    extensionProperties: {}
    installPatches: {
      linuxParameters: {
        classificationsToInclude: [
          'string'
        ]
        packageNameMasksToExclude: [
          'string'
        ]
        packageNameMasksToInclude: [
          'string'
        ]
      }
      rebootSetting: 'ifRequired'
      windowsParameters: {
        classificationsToInclude: [
          'string'
        ]
        excludeKbsRequiringReboot: false
        kbNumbersToExclude: [
          'string'
        ]
        kbNumbersToInclude: [
          'string'
        ]
      }
    }
    maintenanceScope: 'InGuestPatch'
    maintenanceWindow: {
      duration: '03:00'
      expirationDateTime: 'string'
      recurEvery: '1Week'
      startDateTime: 'string'
      timeZone: 'UTC'
    }
    namespace: 'string'
    visibility: 'Custom'
  }
}

output maintenanceConfigId string = maintenanceConfig.id
