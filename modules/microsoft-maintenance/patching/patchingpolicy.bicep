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
          ''
        ]
        packageNameMasksToExclude: [
          ''
        ]
        packageNameMasksToInclude: [
          ''
        ]
      }
      rebootSetting: 'ifRequired'
      windowsParameters: {
        classificationsToInclude: [
          ''
        ]
        excludeKbsRequiringReboot: false
        kbNumbersToExclude: [
          ''
        ]
        kbNumbersToInclude: [
          ''
        ]
      }
    }
    maintenanceScope: 'Host'
    maintenanceWindow: {
      duration: '03:00'
      expirationDateTime: ''
      recurEvery: '1Week'
      startDateTime: ''
      timeZone: 'UTC'
    }
    namespace: ''
    visibility: 'Custom'
  }
}

output maintenanceConfigId string = maintenanceConfig.id
