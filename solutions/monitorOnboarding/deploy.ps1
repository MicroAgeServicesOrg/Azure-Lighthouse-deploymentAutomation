[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$deploymentName = 'loganalytics.bicep',

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
$bicepFile = ".\solutions\monitorOnboarding\main.bicep"

###localTesting - Leave disabled
#$blueprintPath = "."


#Define path to file containing Subscription IDs
$subscriptionFilePath = ".\subscriptionDeployList_testing.csv"

###localTesting - Leave disabled
#$subscriptionFilePath = "..\..\subscriptionDeployList.csv"


#Read Subscription IDs from CSV file and store in an array
$subscriptions = Import-Csv $subscriptionFilePath



# If you have a set of subs that never should have deployments
# But is available to the service principal

#run deployment in each subscription

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        $clientCode = $subscription.clientCode
        Set-AzContext -SubscriptionId $subscriptionId

        if ($testDeploy) {
            New-AzSubscriptionDeployment -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFile -clientCode $clientCode -WhatIf -Verbose
        }
        
        else {
            TurnOnVMs 
            Start-Sleep -Seconds 30
            New-AzSubscriptionDeployment -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFile -clientCode $clientCode
        }

    }

