[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$deploymentName,

    [PArameter(Mandatory=$true)]
    [bool]$testDeploy
)

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





$ErrorActionPreference = "Stop"

#Define path to the bicep artifacts (files)
$bicepFile = ".\solutions\backupOnboarding\main.bicep"

###localTesting - Leave disabled
#$blueprintPath = "."


#region gather all subscription details from table storage
$resourceGroup = "masvc-lighthouseAutomation-rg" 
$storageAccountName = "masvclighthousetables001"
$tableName = "azMSPClients"
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$ctx = $storageAccount.Context
$cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable
$partitionKey1 = "azMSPSubscriptions1"

# Get current subscriptions stored in Table
$currentSubscriptions = Get-AzTableRow `
-table $cloudTable `
-CustomFilter "(onboarded eq true)"
##endregion


#run deployment in each subscription
#converted to Bicep stack deployment on 10/11/2023

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $currentSubscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        $clientCode = $subscription.clientCode
        Set-AzContext -SubscriptionId $subscriptionId

        if ($testDeploy) {
            New-AzSubscriptionDeployment -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFile -clientCode $clientCode -WhatIf -Verbose
        }
        
        else {
            New-AzSubscriptionDeploymentStack -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFile -DenySettingsMode "None" -templateParameterObject @{clientCode = $clientCode} -Verbose -Force

        }

    }

