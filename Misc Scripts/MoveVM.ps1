#This script should only be used to move VMs from vnet to vnet within the same subscription.
#It won't work when moving VMs between subscriptions.
 
#Note you need the AzureRM module installed. The next line will attempt to detect if it is not installed and install it for you.
#If for any reason it doesn't work you will need to DL the module manually.
#Check that AzureRM module is installed and if not then install it
$temp= (Get-Module -ListAvailable | ? {$_.name -eq 'Az'})
if ($temp.count -eq 0) {Install-Module Az}
 
#########Variables################################################
$original_VM_Name = 'azultstapp01'                               #Enter here the VMname which you want to move
$Newnicname = $original_VM_Name +'-nic'                          #The script must create a new nic which will get attached to the destination vNet, name the nic here our leave as is to be automatically named.
$Newnicip = '10.176.131.40'                                      #The primary static ip address of the new Nic (if desired) in the new VNet/Subnet. Leave blank for a dynamic IP address.
$original_VM_resource_group ='rg-sap-nprd-tst-rwu2'              #Enter here the Resource Group name the VM is in
$Destination_vnet_name = 'vnet-dr-01-rwu2'                       #Enter here the vnet you wish to move the VM to
$Destination_subnet_name= 'snet-db-rwu2'                         #Enter here the destination subnet name, This should be the subnet name only, not vNET_name/subnet
$Destination_vnet_resource_group = 'rg-sap-network-rwu2'         #Enter here the RG name that destination vNet belongs to (this can sometimes be different to the VM RG)
$Region = "westus2"                                              #set the region of where to move the VM to
$asName = "as-sap-tst-sbd-rwu2"                                  #set the new AVSet - leave blank if no availability set is desired
########End Varibles##############################################
 
 
 
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
 
 
#Function that creates the new nic and attaches it to the VM
function NewNIC($nicname, $nicip, $vnetname, $snetname, $rg, $region) {
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $rg -Name $vnetname
    if (![string]::IsNullOrEmpty($nicip)) {
        $subnet = Get-AzVirtualNetworkSubnetConfig -Name $snetname -VirtualNetwork $vnet
        $IpConfigName1 = "ipconfig1"
        $IpConfig1     = New-AzNetworkInterfaceIpConfig -Name $IpConfigName1 -Subnet $subnet -PrivateIpAddress $nicip -Primary
        $nic = New-AzNetworkInterface -Name $nicname -ResourceGroupName $original_VM_resource_group -Location $region -IpConfiguration $IpConfig1
    }else{
        $nic = New-AzNetworkInterface -Name $nicname -ResourceGroupName $original_VM_resource_group -Location $region -Subnet ($vnet.Subnets | ? {$_.name -eq $snetname})
    }
    Write-Output $nic.Id
}
 
#Get details on the VM to move
$vm = Get-AzVM -Name $original_VM_Name -ResourceGroupName $original_VM_resource_group
 
#Remove old NIC
$newvm = $vm | Remove-AzVMNetworkInterface
 
#Create new NIC and attach it to destination vNET then attach the new NIC to the VM
Write-Output "Creating the new NIC"
$newvm = Add-AzVMNetworkInterface -VM $newvm -Id (NewNic -nicname $Newnicname -nicip $Newnicip -vnetname $Destination_vnet_name -snetname $Destination_subnet_name -rg $Destination_vnet_resource_group -region $Region)

#Get new Availability Set if needed and add to the new VM configuration
Write-Output "Adding the new Availability Set"
if (![string]::IsNullOrEmpty($asName)) {
$as =  Get-AzAvailabilitySet -ResourceGroupName $original_VM_resource_group -Name $asName
$asRef = New-Object Microsoft.Azure.Management.Compute.Models.SubResource
$asRef.id = $as.id
$newvm.AvailabilitySetReference = $asRef
}

#Remove some info from original VM which conflicts when creating a new VM
Write-Output "Preserving the disk configuration"
$newvm.OSProfile = $null
$newvm.StorageProfile.ImageReference = $null
$newvm.StorageProfile.OsDisk.CreateOption ='attach'
$newvm.StorageProfile.DataDisks | 
        ForEach-Object { $_.CreateOption = "Attach" }
 
#Save VM config and export to temp folder in case you need to roll back
Export-AzResourceGroup -ResourceGroupName $original_VM_resource_group -Resource $vm.Id -path "c:\temp\$original_VM_Name.json"
 
#Remove/delete the VM from Azure.
Write-Output "Removing VM. Disks don't get removed and are readded next"
$vm | Remove-AzVM
 
#Deploy new VM to Azure
Write-Output "Creating the new VM"
New-AzVM -ResourceGroupName $original_VM_resource_group -Location $Region -VM $newvm
Write-Output "Completed"