#This script should only be used to move VMs from vnet to vnet within the same subscription.
#It won't work when moving VMs between subscriptions.
 
#Note you need the AzureRM module installed. The next line will attempt to detect if it is not installed and install it for you.
#If for any reason it doesn't work you will need to DL the module manually.
#Check that AzureRM module is installed and if not then install it
#$temp= (Get-Module -ListAvailable | ? {$_.name -eq 'Az'}) 
#if ($temp.count -eq 0) {Install-Module Az}
 
#########Variables################################################
$original_VM_resource_group ='rg-sap-nprd-new-rwu2'                      #Enter here the Resource Group name the VM is in
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

## Place virtual network created in previous step into a variable. ##
$vnet = Get-AzVirtualNetwork -Name 'vnetmazgblcore01' -ResourceGroupName 'rgmaznasapnetpreprd01'

## Create load balancer frontend configuration and place in variable. ##
$lbip = @{
    Name = 'DB-myFrontEnd'
    PrivateIpAddress = '10.31.10.6'
    SubnetId = $vnet.subnets[0].Id
}
$feip = New-AzLoadBalancerFrontendIpConfig @lbip

## Create backend address pool configuration and place in variable. ##
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name 'myBackEndPool'

## Create the health probe and place in variable. ##
$probe = @{
    Name = 'DB-myHealthProbe'
    Protocol = 'tcp'
    Port = '62550'
    IntervalInSeconds = '5'
    ProbeCount = '2'
    #RequestPath = '/'
}
$healthprobe = New-AzLoadBalancerProbeConfig @probe

## Create the load balancer rule and place in variable. ##
$lbrule = @{
    Name = 'myHTTPRule'
    Protocol = 'All'
    #FrontendPort = '80'
    #BackendPort = '80'
    IdleTimeoutInMinutes = '30'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
    Probe = $healthprobe
}
$rule = New-AzLoadBalancerRuleConfig @lbrule -EnableFloatingIP

## Create the load balancer resource. ##
$loadbalancer = @{
    ResourceGroupName = 'DESuseLinuxVMs'
    Name = 'myLoadBalancer'
    Location = 'eastus2'
    Sku = 'Standard'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
    LoadBalancingRule = $rule
    Probe = $healthprobe
}
New-AzLoadBalancer @loadbalancer