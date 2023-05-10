[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $subscriptionId
)

#Define path to file containing Subscription IDs
$subscriptionFilePath = "$PSScriptRoot\deploytest.csv"

#Read Subscription IDs from CSV file and store in an array
$subscriptions = Import-Csv $subscriptionFilePath


$deploymentName = "masvcbaseline-deployment-backup"
$deploymentLocation = "westus2"
$templateFile = ".\baselineTemplates\azurebackup\main.bicep"
$templateParameterFile = ".\baselineTemplates\azurebackup\parameters.json"

# If you have a set of subs that never should have deployments
# But is available to the service principal
$excludedSubs = (
    "excludedsubIDshere"

)

if ($subscriptionId -eq "ALL") {

    $subscriptions = Get-AzSubscription | Where-Object { $_.Id -NotIn $excludedSubs }
    # getting all subscriptions

    Write-Output "No subscription specified. Deploying to all subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.$subscription.id
        Set-AzContext -SubscriptionId $subscriptionId

        New-AzSubscriptionDeployment -Name $deploymentName -Location $deploymentLocation `
            -TemplateParameterFile $templateParameterFile -TemplateFile $templateFile
    }
}

elseif ((!$subscriptionId) -and ($subscriptions)) {

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        Set-AzContext -SubscriptionId $subscriptionId

        Get-AzStorageAccount | Format-List ResourceGroupName
    }
}

else {
    # using specified subscription

    Write-Output "Subscription specified at pipeline. Targeting $subscriptionId" -Verbose
    Set-AzContext -SubscriptionId $subscriptionId

    Get-AzStorageAccount
}