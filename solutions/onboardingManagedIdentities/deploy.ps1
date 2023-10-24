[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$deploymentName,

    [Parameter(Mandatory=$false)]
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
$bicepFile = ".\solutions\onboardingManagedIdentities\main.bicep"

###localTesting - Leave disabled
#$blueprintPath = "."


#Define path to file containing Subscription IDs
$subscriptionFilePath = ".\subscriptionDeployList.csv"

###localTesting - Leave disabled
#$subscriptionFilePath = "..\..\subscriptionDeployList.csv"


#Read Subscription IDs from CSV file and store in an array
$subscriptions = Import-Csv $subscriptionFilePath



#run deployment in each subscription
#converted to Bicep stack deployment on 10/11/2023

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        $clientCode = $subscription.clientCode
        Set-AzContext -SubscriptionId $subscriptionId

        if ($testDeploy) {
            New-AzSubscriptionDeployment -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFile -clientCode $clientCode -WhatIf -Verbose
        }
        
        else {
            New-AzSubscriptionDeploymentStack -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFile -DenySettingsMode "None" -Verbose -Force

        }

    }

