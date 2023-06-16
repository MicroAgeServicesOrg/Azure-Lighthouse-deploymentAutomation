
param subscriptionId

resource actionGroups 'Microsoft.Insights/actionGroups@2021-04-01-preview' = {
  name: 'masvc-emailsupport'
  location: 'Global'
  properties: {
    groupShortName: 'masvc-emailsupport'
    enabled: true
    emailReceivers: [
      {
        name: 'toSupport'
        emailAddress: 'masalerts@microage.com'
        useCommonAlertsSchema: 'false'
      }
    ]
    // Add other channels as needed (SMS/Push/Voice)
  }
}

resource actionGroupAssociations 'Microsoft.Subscription/tenants/providers/actionGroupAssociations@2021-07-01-preview' = {
  name: 'masvc-emailsupport'
  location: 'Global'
  properties: {
    actionGroupId: actionGroups.id
    scope: subscriptionId
  }
}
