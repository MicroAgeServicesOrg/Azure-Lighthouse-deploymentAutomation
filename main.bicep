/*
Bicep Main file - This file calls all modules within the module folder
Do not edit parameters here. Use the parameters.json file
*/


//Deployment Scope
targetScope = 'subscription'

//Global Parameters
@description('Deployment location/region')
param location string

@description('3 letter Azure region code as defined by Azure Build Standards')
param locationshortcode string

@description('3 letter client code')
param clientcode string

//Variables
var uniqueRGname = '${clientcode}-${locationshortcode}-log-rg'

//Resource Groups
resource logworkspaceRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name:uniqueRGname
  location: location
}




//Modules



module logworkspace 'modules/loganalytics.bicep' = {  //This module will deploy the log analytics workspace to the client tenant
  name: 'lhworkspacedeploy'
  scope: logworkspaceRG
  params: {
    location: location
    locationshortcode: locationshortcode
    clientcode: clientcode
  }
}
