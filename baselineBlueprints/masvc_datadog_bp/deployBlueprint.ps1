[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$blueprintName,

    [Parameter(Mandatory=$false)]
    [bool]$publishBlueprint = $true,

    [Parameter(Mandatory=$false)]
    [string]$blueprintVersion,

    [Parameter(Mandatory=$false)]
    [string]$blueprintChangeNote
)

#Define path to the blueprint artifacts (files)
$blueprintPath = "."


#Define path to file containing Subscription IDs
$subscriptionFilePath = ".\deploytest.csv"

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

        #create Blueprint in subscription
        write-output "Creating Blueprint"
        Import-AzBlueprintWithArtifact -Name $blueprintName -InputPath $blueprintPath -SubscriptionId $subscriptionId

        if ($publishBlueprint -eq "true") {
            $blueprintObject = Get-AzBlueprint -Name $blueprintName
            
            if ($blueprintVersion -eq "Increment") {
                if ($BlueprintObject.versions[$BlueprintObject.versions.count - 1] -eq 0) {
                    $BlueprintVersion = 1
                } else {
                    $BlueprintVersion = ([int]$BlueprintObject.versions[$BlueprintObject.versions.count - 1]) + 1
                }
            }

        }

        if ($blueprintChangeNote) {
            Publish-AzBlueprint -Blueprint $BluePrintObject -Version $BlueprintVersion -ChangeNote $BlueprintChangeNote
        } else {
            Publish-AzBlueprint -Blueprint $BluePrintObject -Version $BlueprintVersion
        }

    }
}


# using specified subscription during deployment "1 sub deployment"
else {

    Write-Output "Subscription specified at pipeline. Targeting $subscriptionId" -Verbose
    Set-AzContext -SubscriptionId $subscriptionId

    Import-AzBlueprintWithArtifact -Name $blueprintName -InputPath $blueprintPath -SubscriptionId $subscriptionId

    if ($publishBlueprint -eq "true") {
        $blueprintObject = Get-AzBlueprint -Name $blueprintName
        
        if ($blueprintVersion -eq "Increment") {
            if ($BlueprintObject.versions[$BlueprintObject.versions.count - 1] -eq 0) {
                $BlueprintVersion = 1
            } else {
                $BlueprintVersion = ([int]$BlueprintObject.versions[$BlueprintObject.versions.count - 1]) + 1
            }
        }

    }

    if ($blueprintChangeNote) {
        Publish-AzBlueprint -Blueprint $BluePrintObject -Version $BlueprintVersion -ChangeNote $BlueprintChangeNote
    } else {
        Publish-AzBlueprint -Blueprint $BluePrintObject -Version $BlueprintVersion
    }

}