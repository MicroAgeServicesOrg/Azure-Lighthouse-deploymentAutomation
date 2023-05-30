$rg = @{ResourceGroup=@{name='storage_rg';location='eastus'}}

$params = @{datadog_ARM_location="WestUS2"; datadog_ARM_clientPrefix="STO"; datadog_ARM_childOrgApiKey="e89d9a71e50a8451e53dcd33dbdf4976"; datadog_ARM_childOrgAppKey="f61bf1fc357e367f2b96718c09622d49221ecca3"}

$subscriptionId = "36b8c29b-b17a-43d6-8451-044becd23c55"

$managedidentity = "/subscriptions/$subscriptionId/resourceGroups/masvc-lighthouseuami-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/microagelighthouseuami"

$blueprintObject =  Get-AzBlueprint -Name "masvc_datadog_bp" -SubscriptionId $subscriptionId


New-AzBlueprintAssignment -Name "masvcbaseline_datadog" -Blueprint $blueprintObject -SubscriptionId $subscriptionId -Location "West US2" -Parameter $params -UserAssignedIdentity $managedidentity

