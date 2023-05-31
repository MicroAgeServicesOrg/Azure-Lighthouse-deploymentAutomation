[CmdletBinding()]
param (
    [Parameter()]
    [string]$subscriptionId,

    [Parameter()]
    [string]$blueprintName
)


$blueprintPath = "$PSScriptRoot"


#Define path to file containing Subscription IDs
$subscriptionFilePath = "$PSScriptRoot\deploytest.csv"

#Read Subscription IDs from CSV file and store in an array
$subscriptions = Import-Csv $subscriptionFilePath



# If you have a set of subs that never should have deployments
# But is available to the service principal

if ((!$subscriptionId) -and ($subscriptions)) {

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        Set-AzContext -SubscriptionId $subscriptionId

        #create Blueprint in subscription
        Import-AzBlueprintWithArtifact -Name $blueprintName -InputPath $blueprintPath -SubscriptionId $subscriptionId
    }
}

else {
    # using specified subscription

    Write-Output "Subscription specified at pipeline. Targeting $subscriptionId" -Verbose
    Set-AzContext -SubscriptionId $subscriptionId

    Get-AzStorageAccount
}