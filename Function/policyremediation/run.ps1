# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}


$tenantId = $env:ARM_TENANT_ID
Set-AzContext -Tenantid $tenantId
$ManagementGroupName = $env:MG_NAME


Write-Host "Getting noncompliant policy assignments for" $ManagementGroupName "..."
$policies += Get-AzPolicyState -ManagementGroupName $ManagementGroupName -Filter "ComplianceState eq 'NonCompliant'" | where-object PolicySetDefinitionName -ne $null
$policyAssignmentIds = @()
foreach ($policy in $policies) {
    $policyAssignmentIds += $policy.PolicyAssignmentId
    
    # $PolicyAssignment = Get-AzPolicyAssignment -Id $policy.PolicyAssignmentId
    # $PolicyDefinition = $(Get-AzPolicySetDefinition -id $PolicyAssignment.Properties.policyDefinitionId)
    # $PolicyDefinitionRefIDs = $($PolicyDefinition.Properties.policyDefinitions).policyDefinitionReferenceId
    # foreach ($PolicyDefinitionRefID in $PolicyDefinitionRefIDs){

    #     Start-AzPolicyRemediation -PolicyAssignmentId $policy.PolicyAssignmentId -PolicyDefinitionReferenceId $PolicyDefinitionRefID -Name "Remediation-$PolicyDefinitionRefID"
    # }
}
$policyAssignmentIds = ($policyAssignmentIds | Select-Object -Unique)
foreach ($policyAssignmentId in $policyAssignmentIds) {
    if (!$policyAssignmentId.EndsWith('securitycenterbuiltin') ) { # security center built in polices don't support this method
        .\Trigger-PolicyInitiativeRemediation.ps1 -ManagementGroup -ManagementGroupId $ManagementGroupName -PolicyAssignmentId  $policyAssignmentId -Force
    }
}
    

