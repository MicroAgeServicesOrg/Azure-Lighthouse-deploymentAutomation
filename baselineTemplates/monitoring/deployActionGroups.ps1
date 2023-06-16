# Define the path to the CSV file containing subscription IDs
$subscriptionFilePath = ".\subscriptionDeployList.csv"

# Read the CSV file
$subscriptions = Import-Csv -Path $subscriptionFilePath

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.SubscriptionId

    # Set the Bicep template parameter values
    $bicepParams = @{
        subscriptionIds = $subscriptionId
    }

    # Define a unique deployment name for each subscription
    $deploymentName = "ActionGroupsDeployment_$subscriptionId"

    # Deploy the Bicep template using Azure CLI
    az deployment group create --name $deploymentName --resource-group masvc-monitoringresources-rg --template-file actionGroups.bicep --parameters $bicepParams

    # Add a delay between each deployment (if needed) to avoid rate limits
    Start-Sleep -Seconds 5
}
