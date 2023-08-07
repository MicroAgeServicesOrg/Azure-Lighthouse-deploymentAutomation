
param clientcode string
param location string = 'westus3'


var uniquelogworkspacename = '${clientcode}-${location}-log-prod'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
    name: uniquelogworkspacename
    location: location
    properties: {
        sku: {
            name: 'PerGB2018'
        }
    }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
