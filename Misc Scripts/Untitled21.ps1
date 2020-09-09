#######################Login to Azure###############################
Write-Host "Log into Azure Services..."

#Clear existing Azure connections
Clear-AzContext -Scope CurrentUser -Force

#Azure Account Login
try {
                Connect-AzAccount -ErrorAction Stop
}
catch {
                # The exception lands in [Microsoft.Azure.Commands.Common.Authentication.AadAuthenticationCanceledException]
                Write-Host "User Cancelled The Authentication" -ForegroundColor Yellow
                exit
}
 
#Prompt to select an Azure subscription
Get-AzSubscription | Out-GridView -OutputMode Single -Title "Select a subscription" | ForEach-Object {$selectedSubscriptionID = $PSItem.SubscriptionId}
 
# Set selected Azure subscription
set-azcontext -SubscriptionId $selectedSubscriptionID
 
 
 
#########################Start Script#############################


$role = Get-AzRoleDefinition "Reader"
$role.Id = $null
$role.Name = "Azure Metrics Reader"
$role.Description = "Can view activity logs and metrics."
$role.Actions.Clear()
$role.Actions.Add("Microsoft.Insights/eventtypes/*")
$role.Actions.Add("Microsoft.Insights/metricalerts/*")
$role.Actions.Add("Microsoft.Insights/metricdefinitions/*")
$role.Actions.Add("Microsoft.Insights/metrics/*")
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/$selectedSubscriptionID")
New-AzRoleDefinition -Role $role 