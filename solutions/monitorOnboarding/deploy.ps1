[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$deploymentName = 'loganalytics.bicep'
)


$ErrorActionPreference = "Stop"

#Define path to the bicep artifacts (files)
$bicepFile = ".\solutions\central-log-analytics-workspace\main.bicep"

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
if ((!$subscriptionId) -and ($subscriptions)) {

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        $clientCode = $subscription.clientCode
        Set-AzContext -SubscriptionId $subscriptionId

        New-AzSubscriptionDeployment -Name $deploymentName -Location "WestUS3" -TemplateFile $bicepFile -clientCode $clientCode
    }
}




# using specified subscription during deployment "1 sub deployment"
else {

    Write-Output "Subscription specified at pipeline. Targeting $subscriptionId" -Verbose
    Set-AzContext -SubscriptionId $subscriptionId

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        Set-AzContext -SubscriptionId $subscriptionId

        New-AzSubscriptionDeployment -Name "devops_azPolicyDefinition_deploy" -Location "WestUS2" -TemplateFile $bicepFile
    }

}
