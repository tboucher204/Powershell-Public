<#PSScriptInfo
 
.VERSION 1.0
 
.GUID 836ca1ab-93b7-49a3-b1d1-b257601da1dd
 
.AUTHOR Microsoft Corporation
 
.COMPANYNAME Microsoft Corporation
 
.COPYRIGHT Microsoft Corporation. All rights reserved.
 
.TAGS Azure, Az, LoadBalancer, AzNetworking
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
 
 
.PRIVATEDATA
 
#>

<#
 
.DESCRIPTION
This script will help you create a Standard SKU Internal load balancer with the same configuration as your Basic SKU load balancer.
   
.PARAMETER rgName
Name of ResourceGroup of Basic Internal Load Balancer and the Standard Internal Load Balancer, like "microsoft_rg1"
.PARAMETER oldLBName
Name of Basic Internal Load Balancer you want to upgrade.
.PARAMETER newlocation
Location where you want to place new Standard Internal Load Balancer in. For example, "centralus"
.PARAMETER newLBName
Name of the newly created Standard Internal Load Balancer.
  
.EXAMPLE
./AzureILBUpgrade.ps1 -rgName "test_InternalUpgrade_rg" -oldLBName "LBForInternal" -newlocation "centralus" -newLbName "LBForUpgrade"
 
.LINK
https://aka.ms/upgradeloadbalancerdoc
https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview/
 
.NOTES
Note - all paramemters are required in order to successfully create a Standard Internal Load Balancer.
 
#> 
Param(
[Parameter(Mandatory = $True)][string] $rgName,
[Parameter(Mandatory = $True)][string] $oldLBName,
#Parameters for new Standard Load Balancer
[Parameter(Mandatory = $True)][string] $newlocation,
[Parameter(Mandatory = $True)][string] $newLBName
)

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

#######################End Login to Azure############################### 
#getting current loadbalancer
$lb = Get-AzLoadBalancer -ResourceGroupName $rgName -Name $oldLbName

#1. Backend subnet is always the same as the froneendipconfig - automaticl association
$rgVnetName = "RG-ILBTestVNET"
$vnetName = "ILBTestVNet"
#$vnetName = ($lb.FrontendIpConfigurations.subnet.id).Split("/")[8]
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
$backendSubnetName = "ILBTest-snet"
#$backendSubnetName = $lb.FrontendIpConfigurations.subnet.id.Split("/")[10]
$backendSubnet = Get-AzVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet
$ipRange = ($backendSubnet.AddressPrefix).split("/")[0]

$newlbFrontendConfigs = $lb.FrontendIpConfigurations
$feProcessed = 1

$startIp = $ipRange.Split(".")[3] + 1
$startIPTest = $ipRange.Split(".")[0] + "." + $ipRange.Split(".")[1] + "." + $ipRange.Split(".")[2] + "." + $startIp

$availableIPS = (Test-AzPrivateIPAddressAvailability -VirtualNetwork $vnet -IPAddress $startIPTest).AvailableIPAddresses

#initial bit in array to check for available ips
$i=0
foreach ($frontEndConfig in $newlbFrontendConfigs)
{
    Get-AzLoadBalancerFrontendIpConfig -Name ($frontEndConfig).Name -LoadBalancer $lb
    $newFrontEndConfigName = $frontEndConfig.Name
    $newFrontEndIp = $availableIPS[$i]
    #$newFrontEndIp = $frontEndConfig.PrivateIpAddress
    $newSubnetId = $frontEndConfig.subnet.Id
    #2. create frontend config
    New-Variable -Name "frontEndIpConfig$feProcessed" -Value (New-AzLoadBalancerFrontendIpConfig -Name $newFrontEndConfigName -PrivateIpAddress $newFrontEndIp -SubnetId $newSubnetId)
    $feProcessed++
    $i++
}
$rulesFrontEndIpConfig = (Get-Variable -Include frontEndIpConfig*)

#2. create inbound nat rule configs
$newlbNatRules = $lb.InboundNatRules
##looping through NAT Rules
$ruleprocessed = 1
foreach ($natRule in $newlbNatRules)
{
    ##need to get correct frontendipconfig
    $frontEndName = (($natRule.FrontendIPConfiguration).id).Split("/")[10]
    $frontEndNameConfig = ((Get-Variable -Include frontEndIpConfig* | Where-Object {$_.Value.name -eq $frontEndName})).value
    New-Variable -Name "nat$ruleprocessed" -Value (New-AzLoadBalancerInboundNatRuleConfig -Name $natRule.name -FrontendIpConfiguration $frontEndNameConfig -Protocol $natRule.Protocol -FrontendPort $natRule.FrontendPort -BackendPort $natRule.BackendPort)
    $ruleprocessed++
}
$rulesNat = (Get-Variable -Include nat* | Where-Object {$_.Name -ne "natRule"})

#3. Create loadbalancer
$newlb = New-AzLoadBalancer -ResourceGroupName $rgName -Name $newLbName -SKU Standard -Location $newLocation -FrontendIpConfiguration $rulesFrontEndIpConfig.Value  -InboundNatRule $rulesNat.Value #-outboundRule $outboundrule

#geting LB now after ceation
$newlb = (Get-AzLoadBalancer  -ResourceGroupName $rgName -Name $newLbName)

$newProbes = Get-AzLoadBalancerProbeConfig -LoadBalancer $lb
foreach ($probe in $newProbes)
{
    $probeName = $probe.name
    $probeProtocol = $probe.protocol
    $probePort = $probe.port
    $probeInterval = $probe.intervalinseconds
    $probeRequestPath = $probe.requestPath
    $probeNumbers = $probe.numberofprobes
    $newlb | Add-AzLoadBalancerProbeConfig -Name $probeName -RequestPath $probeRequestPath -Protocol $probeProtocol -Port $probePort -IntervalInSeconds $probeInterval -ProbeCount $probeNumbers 
    $newlb | Set-AzLoadBalancer
}

$backendArray=@()
$newBackendPools = $lb.BackendAddressPools
$newlb = (Get-AzLoadBalancer -ResourceGroupName $rgName -Name $newLbName)
foreach ($newBackendPool in $newBackendPools)
{
    $existingBackendPoolConfig = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name ($newBackendPool).Name
    $newlb | Add-AzLoadBalancerBackendAddressPoolConfig -Name ($existingBackendPoolConfig).Name | Set-AzLoadBalancer
    $newBackendPoolConfig = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $newlb -Name ($newBackendPool).Name
    $newlb = (Get-AzLoadBalancer -ResourceGroupName $rgName -Name $newLbName)
    write-host "backendpoolconfig"
    #$newBackendPoolConfig
    $nics = ($lb.BackendAddressPools).backendipconfigurations
}

$newlb = (Get-AzLoadBalancer  -ResourceGroupName $rgName -Name $newLbName)
#7. create load balancer rule config
$newLbRuleConfigs = Get-AzLoadBalancerRuleConfig -LoadBalancer $lb
foreach ($newLbRuleConfig in $newLbRuleConfigs)
{
    $backendPool = (Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $newlb -Name ((($newLbRuleConfig.BackendAddressPool.id).split("/"))[10]))
    $lbFrontEndName = (($newLbRuleConfig.FrontendIPConfiguration).id).Split("/")[10]
    $lbFrontEndNameConfig = ((Get-Variable -Include frontEndIpConfig* | Where-Object {$_.Value.name -eq $lbFrontEndName})).value
    $newlb | Add-AzLoadBalancerRuleConfig -Name ($newLbRuleConfig).Name -FrontendIPConfiguration $lbFrontEndNameConfig -BackendAddressPool $backendPool -Probe (Get-AzLoadBalancerProbeConfig -LoadBalancer $newlb -Name (($newLbRuleConfig.Probe.id).split("/")[10])) -Protocol ($newLbRuleConfig).protocol -FrontendPort ($newLbRuleConfig).FrontendPort -BackendPort ($newLbRuleConfig).BackendPort -IdleTimeoutInMinutes ($newLbRuleConfig).IdleTimeoutInMinutes -EnableFloatingIP -LoadDistribution SourceIP -DisableOutboundSNAT
    $newlb | set-AzLoadBalancer
}
