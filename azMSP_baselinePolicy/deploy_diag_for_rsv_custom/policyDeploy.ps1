[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$subscriptionId
)

$ErrorActionPreference = "Stop"

#Define path to the bicep artifacts (files)
$bicepFile = ".\azMSP_baselinePolicy\deploy_diag_for_rsv_custom\policyDeploy.bicep"

###localTesting - Leave disabled
#$blueprintPath = "."


#Define path to file containing Subscription IDs
$subscriptionFilePath = ".\subscriptionDeployList.csv"

###localTesting - Leave disabled
#$subscriptionFilePath = "..\..\subscriptionDeployList.csv"


#Read Subscription IDs from CSV file and store in an array
$subscriptions = Import-Csv $subscriptionFilePath




# If you have a set of subs that never should have deployments
# But is available to the service principal

#create blueprint in each subscription listed in csv
if ((!$subscriptionId) -and ($subscriptions)) {

    Write-Output "Subscriptions sepecified in CSV file. Deploying to selected subscriptions" -Verbose
    foreach ($subscription in $subscriptions) {
        
        $subscriptionId = $subscription.subscriptionID
        Set-AzContext -SubscriptionId $subscriptionId

        New-AzSubscriptionDeployment -Name "devops_deploydiagforRSV" -Location "WestUS2" -TemplateFile $bicepFile
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

        New-AzSubscriptionDeployment -Name "devops_deploydiagforRSV" -Location "WestUS2" -TemplateFile $bicepFile
    }

}
