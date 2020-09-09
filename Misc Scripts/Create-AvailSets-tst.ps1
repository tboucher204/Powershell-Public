#This script should only be used to move VMs from vnet to vnet within the same subscription.
#It won't work when moving VMs between subscriptions.
 
#Note you need the AzureRM module installed. The next line will attempt to detect if it is not installed and install it for you.
#If for any reason it doesn't work you will need to DL the module manually.
#Check that AzureRM module is installed and if not then install it
$temp= (Get-Module -ListAvailable | ? {$_.name -eq 'Az'}) 
if ($temp.count -eq 0) {Install-Module Az}
 
#########Variables################################################
$original_VM_resource_group ='rg-sap-nprd-tst-rwu2'                      #Enter here the Resource Group name the VM is in
$Region = "westus2"                                            #set the location of where to move the VM to
$asNames = "app","ascs","db","sbd"                                              #set the suffix to the new AVSet
########End Varibles###############################################
 
 
 
#######################Login to Azure###############################
Write-Host "Log into Azure Services..."
#Azure Account Login
try {
                Login-AzAccount -ErrorAction Stop
}
catch {
                # The exception lands in [Microsoft.Azure.Commands.Common.Authentication.AadAuthenticationCanceledException]
                Write-Host "User Cancelled The Authentication" -ForegroundColor Yellow
                exit
}
 
#Prompt to select an Azure subscription
Get-AzSubscription | Out-GridView -OutputMode Single -Title "Select a subscription" | ForEach-Object {$selectedSubscriptionID = $PSItem.SubscriptionId}
 
# Set selected Azure subscription
Select-AzSubscription -SubscriptionId $selectedSubscriptionID
 
 
 
#########################Start Script#############################



# Define new Availability Set name for VMs in new VNET
foreach ($element in $asNames) {
  
        $asNewName = "as-sap-${element}-rwu2"

        New-AzAvailabilitySet `
            -ResourceGroupName $original_VM_resource_group `
            -Name $asNewName `
            -Location $Region `
            -Sku "Aligned" `
            -PlatformFaultDomainCount 2 `
            -PlatformUpdateDomainCount 5
}