//Setting the target scope (Subscription Based Deployment)
targetScope = 'subscription'

//Parameters
param policies array = [
  {
    // 1
    name: 'loganalytics_policy.json'
    policyDefinition : json(loadTextContent('./Policy.json'))
    parameters: {}
    identity: false
  }
]



//Policy resource - uses loop in case of multiple policies
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = [for policy in policies: {
  name: guid(policy.name)
  properties: {
    description: policy.policyDefinition.properties.description
    displayName: policy.policyDefinition.properties.displayName
    metadata: policy.policyDefinition.properties.metadata
    mode: policy.policyDefinition.properties.mode
    parameters: policy.policyDefinition.properties.parameters
    policyType: policy.policyDefinition.properties.policyType
    policyRule: policy.policyDefinition.properties.policyRule
  }
}]
