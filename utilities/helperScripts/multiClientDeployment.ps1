[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$deploymentName,

    [Parameter(Mandatory=$false)]
    [bool]$testDeploy,
    
    [Parameter(Mandatory=$false)]
    [string]$clientSubscriptionsJSON,

    [Parameter(Mandatory=$true)]
    [string]$bicepFilePath,

    [Parameter(Mandatory=$false)]
    [hashtable]$templateParams
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

$clientSubscriptions = $clientSubscriptionsJSON | ConvertFrom-Json -AsHashtable

$ErrorActionPreference = "Stop"

#Define path to the bicep artifacts (files) TESTING
#$bicepFileLOCAL = "..\..\solutions\monitorOnboarding\main.bicep"




#run deployment in each subscription
#converted to Bicep stack deployment on 10/11/2023

    Write-Output "Subscriptions sepecified in azTableStorage. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $clientSubscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        Set-AzContext -SubscriptionId $subscriptionId

        if ($testDeploy) {
            New-AzSubscriptionDeployment -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFilePath -WhatIf -Verbose
        }
        
        else {
            New-AzSubscriptionDeploymentStack -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFilePath -templateParameterObject $templateParams -DenySettingsMode "None" -WhatIf -Verbose
        }

    }

