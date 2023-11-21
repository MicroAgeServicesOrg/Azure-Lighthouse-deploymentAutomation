[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="The resource group where the AzTableStorage is located.")]
    [string] $tableResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="The name of the AzTableStorage account.")]
    [string] $tableStorageAccount,

    [Parameter(Mandatory=$true, HelpMessage="The name of the table within the storage account to pull the current client list/filters from.")]
    [string] $tableName
)


$ErrorActionPreference = 'Stop'

<#Powershell script to gather current client subscriptions from AzTableStorage. 

        .SYNOPSIS
            A helper script to check for AzTable module and gather current client subscriptions from AzTableStorage.
            Note this script must be Dot Sourced in order to run correctly. The script will output info into a varaible called $currentSubscriptions.

        .PARAMETER tableResourceGroup
            The resource group where the AzTableStorage is located.
        .PARAMETER tableStorageAccount
            The name of the AzTableStorage account.
        .PARAMETER tableName
            The name of the table within the storage account to pull the current clint list/filters from.
        .EXAMPLE 
            getClientSubscriptionsFromTableStorage -tableResourceGroup 'masvc-lighthouseAutomation-rg' -tableStorageAccount 'masvclighthousetables001' -tableName 'azMSPClients'

#>
#region
#Function to check for AzTable Module and find it if it's not installed. 
function Load-Module ($module = "AzTable") {

    # If module is imported say that and do nothing
    if (Get-Module | Where-Object {$_.Name -eq $module}) {
        write-host "Module $module is already imported."
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $module}) {
            Import-Module $module -Verbose
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $module | Where-Object {$_.Name -eq $module}) {
                Install-Module -Name $module -Force -Verbose -Scope CurrentUser
                Import-Module $module -Verbose
            }
            else {

                # If the module is not imported, not available and not in the online gallery then abort
                write-host "Module $module not imported, not available and not in an online gallery, exiting."
                EXIT 1
            }
        }
    }
}
#endregion

Write-Output "Checking for AzTable Module"
Load-Module


#regionmasvc-lighthouseAutomation-rg
#Function to gather information from table storage. 
function getClientSubscriptionsFromTableStorage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$tableResourceGroup,
        [Parameter(Mandatory = $true)]
        [string]$tableStorageAccount,
        [Parameter(Mandatory = $true)]
        [string]$tableName,

        [switch] $onboardedParamOverride
    )

#Switch to override table column for onboarded.
if ($onboardedParamOverride) {
    $onboardedFilter = "(onboarded eq false)"
}
else {
    $onboardedFilter = "(onboarded eq true)"
}

#set variable for policyRemediationFilter
$policyRemediationFilter = "$onboardedFilter and (policyRemediationEnabled eq true)"


# Get current subscriptions stored in Table
$resourceGroup = $tableResourceGroup
$storageAccountName = $tableStorageAccount
$tableName = $tableName
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$ctx = $storageAccount.Context
$cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable
$partitionKey1 = "azMSPSubscriptions1"

# Get current subscriptions stored in Table
$script:currentSubscriptions = Get-AzTableRow `
-table $cloudTable `
-CustomFilter "$policyRemediationFilter"


Write-Output "Here are the Current Subscriptions approved for onboarding:" $currentSubscriptions
Write-Output "Setting VSO Variable"
Write-Output "##vso[task.setvariable variable=currentSubscriptions;isOutput=true]abc"
}
##endregion


Write-Output "Getting current subscriptions from AzTableStorage"
getClientSubscriptionsFromTableStorage -tableResourceGroup $tableResourceGroup -tableStorageAccount $tableStorageAccount -tableName $tableName -Verbose


