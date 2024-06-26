param(
    [Parameter(Mandatory = $true)] [string] $policyName
)

#region
# Set the variables that are used in the rest of the PowerShell script
Write-Verbose "`nSet the variables that are used in the rest of the PowerShell script"
$today = Get-Date
$yesterday = $today.AddDays(-1)
$createWorkItem = $false

$policyFilterScriptBlock = {
    $_.ComplianceState -eq 'NonCompliant' -and
    $_.PolicySetDefinitionName -eq $policyName -or
    $_.PolicyDefinitionName -eq $policyName
  }
#endregion


#region gather all subscription details from table storage
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
-CustomFilter "(onboarded eq true) and (policyRemediationEnabled eq true)"
##endregion


foreach ($subscription in $currentSubscriptions) {
    Write-Verbose "`nSet the context to the '$($subscription.RowKey)' Subscription"
    Set-AzContext -SubscriptionId $subscription.SubscriptionId


    #region run a compliance scan on the current subscription to gather the latest data. 
    Write-Output "`nRun a compliance scan on the current subscription to gather the latest data"
    $complianceScanJob = Start-AzPolicyComplianceScan -AsJob
    $complianceScanJob | Wait-Job
    #endregion


    #region Get the Azure Policy state and select all the unique non-compliant Policy Definitions
    Write-Output "`nGet the Azure Policy state and select all the unique non-compliant Policy Definitions"
    $complianceState = Get-AzPolicyState -From $yesterday -To $today


    Write-Verbose "`nSelect all the non-compliant instances"
    $nonCompliantInstances = $complianceState | Where-Object -FilterScript $policyFilterScriptBlock


    Write-Verbose "`nSelect all the unique non-compliant Policy Definitions"
    $noncompliantPolicyDefinitions = $nonCompliantInstances | Select-Object -Property PolicyDefinitionName, PolicyDefinitionReferenceId, PolicyAssignmentId -Unique
    Write-Output "`At the moment, there is/are '$($noncompliantPolicyDefinitions.Count)' unique non-compliant Policy Definition(s)"
    #endregion



    #region Create a Remediation Task for each of the non-compliant Policy Definitions. accounts for policies and policy definitions with an if/else statement.
    $failedPolicyRemediationTasks = @()
    foreach ($noncompliantPolicyDefinition in $noncompliantPolicyDefinitions) {
        Write-Output "`nThe '$($noncompliantPolicyDefinition.PolicyDefinitionName)' Policy Definition, assigned by the '$($noncompliantPolicyDefinition.PolicyAssignmentId.Split("/")[-1])' Policy Assignment is not compliant and thus needs to be remediated"
        try {
            if (!($noncompliantPolicyDefinition.PolicyDefinitionReferenceId)) {
                Write-Verbose "`tThe '$($noncompliantPolicyDefinition.PolicyDefinitionName)' Policy Definition is not part of a Policy Set. Therefore, the 'Start-AzPolicyRemediation' command does not use the -PolicyDefinitionReferenceId parameter"
                $params = @{
                    'Name'               = $noncompliantPolicyDefinition.PolicyDefinitionName
                    'PolicyAssignmentId' = $noncompliantPolicyDefinition.PolicyAssignmentId
                }
            }
            else {
                Write-Verbose "`tThe '$($noncompliantPolicyDefinition.PolicyDefinitionName)' Policy Definition is part of a Policy Set. Therefore, the 'Start-AzPolicyRemediation' command does use the -PolicyDefinitionReferenceId parameter"
                $params = @{
                    'Name'                        = $noncompliantPolicyDefinition.PolicyDefinitionName
                    'PolicyAssignmentId'          = $noncompliantPolicyDefinition.PolicyAssignmentId
                    'PolicyDefinitionReferenceId' = $noncompliantPolicyDefinition.PolicyDefinitionReferenceId
                }
            }
            $newPolicyRemediationTask = Start-AzPolicyRemediation @params
            if ($newPolicyRemediationTask.ProvisioningState -eq 'Succeeded') {
                Write-Output "`tThe provisioning state of the Remediation Task is set to Succeeded. Moving on to the next non-compliant Policy Definition"
            }
            elseif ($newPolicyRemediationTask.ProvisioningState -eq 'Failed') {
                Write-Output "`tThe provisioning state of the Remediation Task is set to Failed. Adding it to the array of failed Remediation Tasks"
                $failedPolicyRemediationTask = [PSCustomObject]@{
                    'Remediation Task Name' = $newPolicyRemediationTask.Name
                    'Remediation Task Id'   = $newPolicyRemediationTask.Id
                    'Policy Assignment Id'  = $newPolicyRemediationTask.PolicyAssignmentId
                    'Provisioning State'    = $newPolicyRemediationTask.ProvisioningState
                }
                $failedPolicyRemediationTasks += $failedPolicyRemediationTask
            }
            else {
                Write-Output "`tThe Remediation Task has not succeeded or failed right away. Continuing to check the provisioning state until it changes to Succeeded or Failed"
                do {
                    Start-Sleep -Seconds 60
                    $existingPolicyRemediationTask = Get-AzPolicyRemediation -ResourceId $newPolicyRemediationTask.Id
                    if ($existingPolicyRemediationTask.ProvisioningState -eq 'Succeeded') {
                        Write-Output "`tThe provisioning state of the Remediation Task has changed to Succeeded. Moving on to the next non-compliant Policy Definition"
                    }
                    elseif ($existingPolicyRemediationTask.ProvisioningState -eq 'Failed') {
                        Write-Output "`tThe provisioning state of the Remediation Task has changed to Failed. Adding it to the array of failed Remediation Tasks"
                        $failedPolicyRemediationTask = [PSCustomObject]@{
                            'Remediation Task Name' = $existingPolicyRemediationTask.Name
                            'Remediation Task Id'   = $existingPolicyRemediationTask.Id
                            'Policy Assignment Id'  = $existingPolicyRemediationTask.PolicyAssignmentId
                            'Provisioning State'    = $existingPolicyRemediationTask.ProvisioningState
                        }
                        $failedPolicyRemediationTasks += $failedPolicyRemediationTask
                        break
                    }
                    else {
                        Write-Output "`tThe provisioning state of the Remediation Task has not changed to Failed or Succeeded. Continuing to check the provisioning state"
                    }
                } until ($existingPolicyRemediationTask.ProvisioningState -eq 'Succeeded')
            }
        }
        catch {
            Write-Error $_
        }
    }
}
#endregion





