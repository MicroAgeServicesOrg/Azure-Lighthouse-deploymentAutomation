/*
Bicep Main file - This file calls all modules within the module folder
Do not edit parameters here. Use the parameters.json file
*/

//Global Parameters
@description('Deployment location/region')
param location string

@description('3 letter Azure region code as defined by Azure Build Standards')
param locationshortcode string

@description('3 letter client code')
param clientcode string




//Modules

module logworkspace 'modules/loganalytics.bicep' = {
  name: 'lhworkspacedeploy'
  params: {
    location: location
    locationshortcode: locationshortcode
    clientcode: clientcode
  }
}
