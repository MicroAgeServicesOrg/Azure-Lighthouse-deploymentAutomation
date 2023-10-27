# Table storage details
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

#loop through subscriptions in table, and get policy compliance state
foreach ($subscription in $currentSubscriptions) {
    $subscriptionId = $subscription.SubscriptionId
    $clientName = $subscription.RowKey
    Write-Output "This is the latest policy compliance states generated in the last day for all resources within the specified Subscription: $clientName"
    Set-AzContext -SubscriptionId $subscriptionId
    Get-AzPolicyStateSummary -SubscriptionId $subscriptionId

}


