[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [switch]$getClientListOnly,

    [Parameter(Mandatory=$false)]
    [string]$deploymentName,

    [Parameter(Mandatory=$false)]
    [bool]$testDeploy,

    [Parameter(Mandatory=$false)]
    [string]$bicepFilePath,

    [Parameter(Mandatory=$false)]
    [hashtable]$templateParams,

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


#######################################################################################################################
#######################################################################################################################
#Functions#

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

function TurnOnVMs {
    # Get all turned off VMs in the subscription
    $vms = Get-AzVM -Status | Where-Object {$_.PowerState -eq 'VM deallocated'}

    # Define the tag to exclude VMs
    $excludeTag = "DoNotTurnOn"

    # Turn on each VM in parallel
    $vms | ForEach-Object -Parallel {
        $vm = $_
        # Check if the VM has the exclude tag
        if ($vm.Tags.ContainsValue($excludeTag)) {
            Write-Output "Skipping VM $($vm.Name) because it has the $excludeTag tag."
        }
        else {
            # Turn on the VM
            Write-Output "Turning on VM $($vm.Name)..."
            Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
        }
    }
}
# Call the function to execute the code
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
}

#######################################################################################################################
#######################################################################################################################
#Start Script#
#region 
if ($getClientListOnly) {
    Write-Output "Checking for AzTable Module"
    Load-Module

    Write-Output "Getting current subscriptions from AzTableStorage"
    getClientSubscriptionsFromTableStorage -tableResourceGroup $tableResourceGroup -tableStorageAccount $tableStorageAccount -tableName $tableName -Verbose
    
    Write-Output "Here are the Current Subscriptions approved for onboarding:" $currentSubscriptions
    exit
}
else {
    Write-Output "Checking for AzTable Module"
    Load-Module
    

    Write-Output "Getting current subscriptions from AzTableStorage"
    getClientSubscriptionsFromTableStorage -tableResourceGroup $tableResourceGroup -tableStorageAccount $tableStorageAccount -tableName $tableName -Verbose

#run deployment in each subscription
#converted to Bicep stack deployment on 10/11/2023

Write-Output "Subscriptions sepecified in azTableStorage. Deploying to selected subscriptions" -Verbose
foreach ($subscription in $currentSubscriptions) {
    
    $subscriptionId = $subscription.subscriptionID
    Set-AzContext -SubscriptionId $subscriptionId

    if ($testDeploy) {
        New-AzSubscriptionDeployment -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFilePath -templateParameterObject $templateParams -WhatIf -Verbose
    }
    
    else {
        New-AzSubscriptionDeploymentStack -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFilePath -templateParameterObject $templateParams -DenySettingsMode "None" -WhatIf -Verbose
    }

}
}
#endregion

#End Script Section#



