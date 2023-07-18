
param clientcode string
param location string
param locationshortcode string


var uniquelogworkspacename = '${clientcode}-${locationshortcode}-log-prod'

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
