# -------------------------------------------------------------------------------------------------------------- 
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,  
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED  
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
# 
#  Title         : AzureARMVMDetailedInventorywithTags 
#  Programmed by : Denis Rougeau
#  Modified by   : Tim Boucher 
#  Date          : Feb, 2019 
#  
# Script to create Azure ARM VM List into a CSV files with VM Tags as header (One file per subscription) 
#
# NOTE: Support for multiple NIC, IP, Public IP, Data Disks per VMs
#       Multiple values within the same field are separated by " Carriage Return "
#       Added support for Managed Disks and Premium disks
#
# Headers:
# - Az_Location
# - Az_ResourceGroup
# - Az_Name
# - Az_Status                     -> Running/Stopped/Deallocated
# - Az_Statuscode                 -> OK/Failed... VM in Error status
# - Az_AvZone                     -> Availability Zone    *** NEW PREVIEW ***
# - Az_AvSet
# - Az_Size                       -> VM Size (ex. Standard_A1_V2)
# - Az_Cores                      -> # Cores
# - Az_Memory                     -> Memory size
# - Az_OSType                     -> Windows/Linux
# - Az_VNicNames                  -> Display all VNics name attached to the VM
# - Az_VNicProvisioningState      -> Succeeded/Failed.  NIC Provisionning Status
# - Az_VNicPrivateIPs
# - Az_vNicPrivateIPAllocMethods  -> Static/Dynamic
# - Az_VirtualNetworks
# - Az_Subnets
# - Az_VNicPublicIP
# - Az_VNicPublicIPAllocMethod    -> Static/Dynamic
# - Az_VM_Instance_SLA            -> If all VM disks are Premium and VM is a xS_ series, Azure offer 99.9 percent service-level agreement(SLA) (https://azure.microsoft.com/en-us/support/legal/sla/virtual-machines/)
# - Az_OSDisk
# - Az_OSDiskHCache               -> Disk Host Caching Setting     *** NEW ***
# - Az_OSDiskSize
# - Az_OSDiskTier                 -> Unmanaged/Managed...     [Modified]  
# - Az_OSDiskRepl                 -> Standard/Premium LRS/GRS/GRS-RA/...   
# - Az_DataDisks                  -> Display all data disks name attached to the VM
# - Az_DataDisksHCache            -> Disk Host Caching Setting     *** NEW ***
# - Az_DataDisksSize
# - Az_DataDisksTier              -> Unmanaged/Managed...     [Modified] 
# - Az_DataDisksRepl              -> Standard/Premium LRS/GRS/GRS-RA/...   
# - Az_VMTags                     -> List all VM tags in one field
# - Az_VMTag [0-14]               -> Make each VM tags it's own header in the Output
# -------------------------------------------------------------------------------------------------------------- 

#Import-Module Az

# TO BE MODIFIED AS APPROPRIATE.  Currently start the file name with datetime stamp.  1 file per subscription
$OutputCSVPath = "c:\temp\" 
$OutputCSVFile = "{0:yyyyMMddHHmm}-AzureARMVMList" -f (Get-Date) 
$outputCSVExt  = ".csv"
$outputLOG     = ''
$outputLOGExt  = ".log" 
$changelist    = ''
 

# Login to Azure Reaource Manager
#Login-AzAccount
#Connect-AzAccount 
 
Function GetDiskSize ($DiskURI) 
{ 
  # User running the script must have Read access to the VM Storage Accounts for these values to be retreive
  $error.clear() 
  $DiskContainer = ($DiskURI.Split('/'))[3]  
  $DiskBlobName  = ($DiskURI.Split('/'))[4]  
 
  # Create Return PS object
  $BlobObject = @{'Name'=$DiskURI;'SkuName'=" ";'SkuTier'=" ";'DiskSize'=0}

  # Avoid connecting to Storage if last disk in same Storage Account (Save significant time!) 
  if ($global:DiskSA -ne ((($DiskURI).Split('/')[2]).Split('.'))[0]) 
  { 
    $global:DiskSA = ((($DiskURI).Split('/')[2]).Split('.'))[0] 
    $global:SAobj = $AllARMSAs | where-object {$_.StorageAccountName -eq $DiskSA} 
    $SARG  = $global:SAobj.ResourceGroupName 
    $SAKeys     = Get-AzStorageAccountKey -ResourceGroupName $SARG -Name $DiskSA 
    $global:SAContext  = New-AzureStorageContext -StorageAccountName $DiskSA  -StorageAccountKey $SAKeys[0].value  
  } 

  $DiskObj = get-azurestorageblob -Context $SAContext -Container $DiskContainer -Blob $DiskBlobName 
  if($Error) 
    {   
       $BlobObject.DiskSize = -1  
       $error.Clear() 
    } 
  else 
    { 
      [int] $DiskSize = $Diskobj.Length/1024/1024/1024 # GB
      $BlobObject.DiskSize = $DiskSize
      $BlobObject.SkuName = $global:SAobj.Sku.Name
      $BlobObject.SkuTier = $global:SAobj.Sku.Tier 
    }  
 
  Return $BlobObject  

  trap { 
      Return $BlobObject 
    } 
} 
 
# Get Start Time 
$startDTM = (Get-Date) 
"Starting Script: {0:yyyy-MM-dd HH:mm}..." -f $startDTM 
$outputLOG = "Starting Script: {0:yyyy-MM-dd HH:mm}..." -f $startDTM
Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
# Get a list of all subscriptions (or a single subscription) 
#"Retrieving all Subscriptions..." 
#$Subscriptions = Get-AzSubscription | Sort SubscriptionName  
#"Found: " + $Subscriptions.Count
  
# ***  NOTE: Uncomment the following line if you want to limit the query to a specific subscription 
$Subscriptions = Get-AzSubscription | ? {$_.Name -eq "Microsoft Azure Sponsorship 2017"} 
"Connecting to: " + $Subscriptions.Name 
$outputLOG = "Connecting to: " + $Subscriptions.Name
Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
# Retrieve all available Virtual Machine Sizes 
"`r`nRetrieving all available Virtual Machines Sizes..." 
$outputLOG = "`r`nRetrieving all available Virtual Machines Sizes..."
Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
$AllVMsSize = Get-AzVMSize -Location "West US"  #  Using West US and South Central US and East US 2 as those 2 locations are usually the ones with all and newer VM sizes 
$AllVMsSizeSCU = Get-AzVMSize -Location "South Central US" 
foreach ($VMsSizeSCU in $AllVMsSizeSCU) 
{ 
    if ($AllVMsSize.Name -notcontains $VMsSizeSCU.Name) { $AllVMsSize += $VMsSizeSCU } 
} 
$AllVMsSizeEU2s = Get-AzVMSize -Location "East US 2" 
foreach ($VMsSizeEU2 in $AllVMsSizeEU2s) 
{ 
    if ($AllVMsSize.Name -notcontains $VMsSizeEU2.Name) { $AllVMsSize += $VMsSizeEU2 } 
} 
"Found: " + $AllVMsSize.Count
$outputLOG = "Found: " + $AllVMsSize.Count 
Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
# Loop thru all subscriptions 
$AzureVMs = @() 
foreach($subscription in $Subscriptions)  
{ 
    $SubscriptionID = $Subscription.Id  
    $SubscriptionName = $Subscription.Name 
    "`r`nQuerying Subscription: $SubscriptionName ($SubscriptionID)"
    $outputLOG = "`r`nQuerying Subscription: $SubscriptionName ($SubscriptionID)" 
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
    Select-AzSubscription -SubscriptionId $SubscriptionID | Out-Null

    # Get Last CSV
    "0- Retrieving last CSV Ouptut (If any exists)..."
    $outputLOG = "0- Retrieving last CSV Ouptut (If any exists)..."
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
    $LastFile = Get-ChildItem $OutputCSVPath -Filter "*$SubscriptionName*$outputCSVExt" | Sort-Object Name -Descending | Select-Object -First 1 FullName
    
    if($LastFile) {
        $ImportedFile = Import-CSV $LastFile.FullName
        "   Found: " + $LastFile.FullName
        $outputLOG = "   Found: " + $LastFile.FullName
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
    } else {
        $ImportedFile = ""
        "   Found: No Previous File Found"
        $outputLOG = "   Found: No Previous File Found"
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
    }

    # Retrieve all Public IPs 
    "1- Retrieving all Public IPs..."
    $outputLOG = "1- Retrieving all Public IPs..."
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
    $AllPublicIPs = get-Azpublicipaddress 
    "   Found: " + $AllPublicIPs.Count
    $outputLOG = "   Found: " + $AllPublicIPs.Count
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
    # Retrieve all Virtual Networks 
    "2- Retrieving all Virtual Networks..." 
    $outputLOG = "2- Retrieving all Virtual Networks..."
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG  
    $AllVirtualNetworks = get-Azvirtualnetwork 
    "   Found: " + $AllVirtualNetworks.Count
    $outputLOG = "   Found: " + $AllVirtualNetworks.Count
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
    # Retrieve all Network Interfaces 
    "3- Retrieving all Network Interfaces..." 
    $outputLOG = "3- Retrieving all Network Interfaces..."
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
    $AllNetworkInterfaces = Get-AzNetworkInterface 
    "   Found: " + $AllNetworkInterfaces.Count 
    $outputLOG = "   Found: " + $AllNetworkInterfaces.Count
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
  
    # Retrieve all ARM Virtual Machines 
    "4- Retrieving all ARM Virtual Machines..." 
    $outputLOG = "4- Retrieving all ARM Virtual Machines..."
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
    $AllARMVirtualMachines = get-Azvm | Sort location,resourcegroupname,name 
    "   Found: " + $AllARMVirtualMachines.Count 
    $outputLOG = "   Found: " + $AllARMVirtualMachines.Count
    Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
    # Skip further steps if no ARM VM found 
    if($AllARMVirtualMachines.Count -gt 0) 
    { 
 
        # Intitialize Storage Account Context variable 
        $global:DiskSA = "" 
 
        # Retrieve all ARM Storage Accounts 
        "5- Retrieving all ARM Storage Accounts..." 
        $outputLOG = "5- Retrieving all ARM Storage Accounts..."
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
        $AllARMSAs = Get-AzStorageAccount 
        "   Found: " + $AllARMSAs.Count
        $outputLOG = "   Found: " + $AllARMSAs.Count
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG 
 
        # Retrieve all Managed Disks 
        "6- Retrieving all Managed Disks..." 
        $outputLOG = "6- Retrieving all Managed Disks..."
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
        $AllMAnagedDisks = Get-AzDisk 
        "   Found: " + $AllManagedDisks.Count 
        $outputLOG = "   Found: " + $AllManagedDisks.Count
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG

        # Retrieve all ARM Virtual Machine tags 
        "7- Capturing all ARM Virtual Machines Tags..."
        $outputLOG = "7- Capturing all ARM Virtual Machines Tags..."
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
        $AllVMTags =  @() 
        foreach ($virtualmachine in $AllARMVirtualMachines) 
        { 
            $tags = $virtualmachine.Tags 
            $tKeys = $tags | select -ExpandProperty keys 
            foreach ($tkey in $tkeys) 
            { 
              
              if ($AllVMTags -notcontains $tkey.ToUpper()) { $AllVMTags += $tkey.ToUpper() } 
            } 
        } 
        "   Found: " + $AllVMTags.Count
        $outputLOG = "   Found: " + $AllVMTags.Count
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
  
        # This script support up to 15 VM Tags, Increasing $ALLVMTags array to support up to 15 if less then 15 found 
        for($i=$($AllVMTags.Count);$i -lt 15; $i++) { $AllVMTags += "Az_VMTag$i"  } #Default Header value  
 
        # Capturing all ARM VM Configurations details 
        "8- Capturing all ARM VM Configuration Details...     (This may take a few minutes)" 
        $outputLOG = "8- Capturing all ARM VM Configuration Details...     (This may take a few minutes)"
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
        $AzureVMs = foreach ($virtualmachine in $AllARMVirtualMachines) 
        { 
            $location = $virtualmachine.Location 
            $rgname = $virtualmachine.ResourceGroupName 
            $vmname = $virtualmachine.Name 
            $vmid = $virtualmachine.VmId
            $vmavzone = $virtualmachine.Zones[0]
 
            # Format Tags, sample: "key : Value <CarriageReturn> key : value "   TAGS keys are converted to UpperCase 
            $taglist = '' 
            $tLogicalis = ''
            $ThisVMTags = @(' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ')  # Array of VMTags matching the $AllVMTags (Header) 
            $tags = $virtualmachine.Tags 
            $tKeys = $tags | select -ExpandProperty keys 
            $tvalues = $tags | select -ExpandProperty values 
            if($tags.Count -eq 1)  
            { 
                  $taglist = $tkeys+":"+$tvalues 
                  $ndx = [array]::IndexOf($AllVMTags,$tKeys.ToUpper())  # Find position of header matching the Tag key 
                  $ThisVMTags[$ndx] = $tvalues 

                  # Check to see if Logicalis Tag is present
                  if($tkeys.ToUpper() -eq "LOGICALIS")
                  {
                    $tLogicalis = $tvalues
                  }
                  else
                  {
                    $tLogicalis = "No tag found"
                  }
            } 
            else 
              { 
                For ($i=0; $i -lt $tags.count; $i++)  
                { 
                  $tkey = $tkeys[$i] 
                  $tvalue = $tvalues[$i] 
                  $taglist = $taglist+$tkey+":"+$tvalue+"`n" 
                  $ndx = [array]::IndexOf($AllVMTags,$tKey.ToUpper())   # Find position of header matching the Tag key 
                  $ThisVMTags[$ndx] = $tvalue 

                  # Check to see if Logicalis Tag is present
                  if($tkey.ToUpper() -eq "LOGICALIS")
                  {
                    $tLogicalis = $tvalue
                  }
                }

                if($tLogicalis -eq '')
                {
                   $tLogicalis = "No tag found"
                }
              }

            # Get for LOGICALIS Tag Changes
            foreach ($vm in $ImportedFile) {
                if ($vm.AZ_VmId -eq $vmid) {
                    if($vm.LOGICALIS -ne $tLogicalis) {
                        Write-Host "   WARNING: $vmname changed from "$vm.LOGICALIS" to $tLogicalis"
                        $outputLOG = "   WARNING: $vmname changed from "+$vm.LOGICALIS+" to $tLogicalis"
                        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
                        $changelist = $changelist+$vmname+" - ("+$vm.Az_VNicPrivateIPs+")"+" has changed from "+$vm.LOGICALIS+" to "+$tLogicalis+"`n"
                    }
                    
                }
            }
             
            # Get VM Status 
            $Status = get-Azvm -Status -ResourceGroupName "$rgname" -Name "$vmname" 
            $vmstatus =  $Status.Statuses[1].DisplayStatus 
 
            # Get Availability Set 
            $AllRGASets = get-Azavailabilityset -ResourceGroupName $rgname 
            $VMASet = $AllRGASets | Where-Object {$_.id -eq $virtualmachine.AvailabilitySetReference.Id} 
            $ASet = $VMASet.Name 
 
            # Get Number of Cores and Memory 
            $VMSize = $AllVMsSize | Where-object {$_.Name -eq $virtualmachine.HardwareProfile.VmSize}  
            $VMCores = $VMSize.NumberOfCores 
            $VMMem = $VMSize.MemoryInMB/1024 
 
            # Get VM Network Interface(s) and properties 
            $MatchingNic = "" 
            $NICName = @()
            $NICProvState = @() 
            $NICPrivateIP = @() 
            $NICPrivateAllocationMethod = @() 
            $NICVNet = @() 
            $NICSubnet = @() 
            foreach($vnic in $VirtualMachine.NetworkProfile.NetworkInterfaces) 
            { 
                $MatchingNic = $AllNetworkInterfaces | where-object {$_.id -eq $vnic.id} 
                $NICName += $MatchingNic.Name 
                $NICProvState += $MatchingNic.ProvisioningState
                $NICPrivateIP += $MatchingNic.IpConfigurations.PrivateIpAddress 
                $NICPrivateAllocationMethod += $MatchingNic.IpConfigurations.PrivateIpAllocationMethod 
                $NICSubnetID = $MatchingNic.IpConfigurations.Subnet.Id 
         
                # Identifying the VM Vnet 
                $VMVNet = $AllVirtualNetworks | where-object {$_.Subnets.id -eq $NICSubnetID } 
                $NICVnet += $VMVNet.Name 
 
                # Identifying the VM subnet 
                $AllVNetSubnets = $VMVNet.Subnets   
                $vmSubnet = $AllVNetSubnets | where-object {$_.id -eq $NICSubnetID }  
                $NICSubnet += $vmSubnet.Name 
 
                # Identifying Public IP Address assigned 
                $VMPublicIPID = $MatchingNic.IpConfigurations.PublicIpAddress.Id 
                $VMPublicIP = $AllPublicIPs | where-object {$_.id -eq $VMPublicIPID } 
                $NICPublicIP = $VMPublicIP.IPAddress 
                $NICPublicAllocationMethod = $VMPublicIP.PublicIpAllocationMethod 
 
            } 

            # Get VM OS Disk properties 
            $OSDiskName = '' 
            $OSDiskSize = 0
            $OSDiskRepl = '' 
            $OSDiskTier = ''
            $OSDiskHCache = ''  # Init/Reset

            # Get OS Disk Caching if set 
            $OSDiskHCache = $virtualmachine.StorageProfile.osdisk.Caching

            # Check if OSDisk uses Storage Account
            if($virtualmachine.StorageProfile.OsDisk.ManagedDisk -eq $null)
            {
                # Retreive OS Disk Replication Setting, tier (Standard or Premium) and Size 
                $VMOSDiskObj = GetDiskSize $virtualmachine.StorageProfile.OsDisk.Vhd.uri
                $OSDiskName = $VMOSDiskObj.Name 
                $OSDiskSize = $VMOSDiskObj.DiskSize
                $OSDiskRepl = $VMOSDiskObj.SkuName 
                $OSDiskTier = "Unmanaged"
            }
            else
            {
                $OSDiskID = $virtualmachine.StorageProfile.OsDisk.ManagedDisk.Id
                $VMOSDiskObj = $AllMAnagedDisks | where-object {$_.id -eq $OSDiskID }
                $OSDiskName = $VMOSDiskObj.Name 
                $OSDiskSize = $VMOSDiskObj.DiskSizeGB
                $OSDiskRepl = $VMOSDiskObj.AccountType
                $OSDiskTier = "Managed"
            }

            $AllVMDisksPremium = $true 
            if($OSDiskRepl -notmatch "Premium") { $AllVMDisksPremium = $false } 

            # Get VM Data Disks and their properties 
            $DataDiskObj = @()
            $VMDataDisksObj = @() 
            foreach($DataDisk in $virtualmachine.StorageProfile.DataDisks) 
            { 

              # Initialize variable before each iteration
              $VMDataDiskName = ''
              $VMDataDiskSize = 0
              $VMDataDiskRepl = ''
              $VMDataDiskTier = ''
              $VMDataDiskHCache = '' # Init/Reset 

              # Get Data Disk Caching if set 
              $VMDataDiskHCache = $DataDisk.Caching
              
              # Check if this DataDisk uses Storage Account
              if($DataDisk.ManagedDisk -eq $null)
              {
                # Retreive OS Disk Replication Setting, tier (Standard or Premium) and Size 
                $VMDataDiskObj = GetDiskSize $DataDisk.vhd.uri 
                $VMDataDiskName = $VMDataDiskObj.Name
                $VMDataDiskSize = $VMDataDiskObj.DiskSize
                $VMDataDiskRepl = $VMDataDiskObj.SkuName
                $VMDataDiskTier = "Unmanaged"
              }
              else
              {
                $DataDiskID = $DataDisk.ManagedDisk.Id
                $VMDataDiskObj = $AllMAnagedDisks | where-object {$_.id -eq $DataDiskID }
                $VMDataDiskName = $VMDataDiskObj.Name
                $VMDataDiskSize = $VMDataDiskObj.DiskSizeGB
                $VMDataDiskRepl = $VMDataDiskObj.AccountType
                $VMDataDiskTier = "Managed"
              }

              # Add Data Disk properties to arrray of Data disks object
              $DataDiskObj += @([pscustomobject]@{'Name'=$VMDataDiskName;'HostCache'=$VMDataDiskHCache;'Size'=$VMDataDiskSize;'Repl'=$VMDataDiskRepl;'Tier'=$VMDataDiskTier})

              # Check if this datadisk is a premium disk.  If not, set the all Premium disks to false (No SLA)
              if($VMDataDiskRepl -notmatch "Premium") { $AllVMDisksPremium = $false } 
            } 
                        
            # Create custom PS objects and return all these properties for this VM 
            [pscustomobject]@{ 
                            Az_Location = $virtualmachine.Location 
                            Az_ResourceGroup = $virtualmachine.ResourceGroupName 
                            Az_Name = $virtualmachine.Name 
                            Az_VmId = $virtualmachine.VmId
                            Az_Status = $vmstatus 
                            #Az_Statuscode = $virtualmachine.StatusCode
                            #AZ_AvZone = $vmavzone 
                            #Az_AvSet = $ASet 
                            Az_Size = $virtualmachine.HardwareProfile.VmSize 
                            #Az_Cores = $VMCores 
                            #Az_Memory = $VMMem 
                            Az_OSType = $virtualmachine.StorageProfile.OsDisk.OsType 
                            #Az_VNicNames = $NICName -join "`n" 
                            #Az_VNicProvisioningState = $NICProvState -join "`n" 
                            Az_VNicPrivateIPs = $NICPrivateIP -join "`n" 
                            #Az_vNicPrivateIPAllocMethods = $NICPrivateAllocationMethod -join "`n" 
                            #Az_VirtualNetworks = $NICVnet -join "`n" 
                            #Az_Subnets = $NICSubnet -join "`n" 
                            Az_VNicPublicIP = $NICPublicIP 
                            #Az_VNicPublicIPAllocMethod = $NICPublicAllocationMethod 
                            #Az_VM_Instance_SLA = $AllVMDisksPremium
                            #Az_OSDisk = $OSDiskName 
                            #Az_OSDiskHCache = $OSDiskHCache
                            #Az_OSDiskSize = $OSDiskSize
                            #Az_OSDiskTier = $OSDiskTier  
                            #Az_OSDiskRepl = $OSDiskRepl 
                            #Az_DataDisks = $DataDiskObj.Name -join "`n" 
                            #Az_DataDisksHCache = $DataDiskObj.HostCache -join "`n" 
                            #Az_DataDisksSize = $DataDiskObj.Size -join "`n" 
                            #Az_DataDisksTier = $DataDiskObj.Tier -join "`n"
                            #Az_DataDisksRepl = $DataDiskObj.Repl -join "`n"
                            Az_VMTags = $taglist 
                            #$AllVMTags[0] = $ThisVMTags[0] 
                            #$AllVMTags[1] = $ThisVMTags[1] 
                            #$AllVMTags[2] = $ThisVMTags[2] 
                            #$AllVMTags[3] = $ThisVMTags[3] 
                            #$AllVMTags[4] = $ThisVMTags[4] 
                            #$AllVMTags[5] = $ThisVMTags[5] 
                            #$AllVMTags[6] = $ThisVMTags[6] 
                            #$AllVMTags[7] = $ThisVMTags[7] 
                            #$AllVMTags[8] = $ThisVMTags[8] 
                            #$AllVMTags[9] = $ThisVMTags[9] 
                            #$AllVMTags[10] = $ThisVMTags[10] 
                            #$AllVMTags[11] = $ThisVMTags[11] 
                            #$AllVMTags[12] = $ThisVMTags[12] 
                            #$AllVMTags[13] = $ThisVMTags[13] 
                            #$AllVMTags[14] = $ThisVMTags[14]
                            LOGICALIS = $tLogicalis
            }
 
        }  #Array $AzureVMs 

        # Define CSV Output Filename, use subscription name and ID as name can be duplicate 
        $OutputCSV = "$OutputCSVPath$OutputCSVFile - $subscriptionName ($SubscriptionID)$outputCSVExt" 
 
        # CSV Exports Virtual Machines 
        "`r`nExporting Results to CSV file: $OutputCSV"
        $outputLOG = "`r`nExporting Results to CSV file: $OutputCSV" 
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
        $CSVResult = $AzureVMs | Export-Csv $OutputCSV -NoTypeInformation 

        # Email CSV
        "Emailing CSV Report..."
        $outputLOG = "Emailing CSV Report..."
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
        $smtpCred = (Get-Credential)
        $ToAddress = 'tim.boucher@us.logicalis.com'
        $FromAddress = 'tim.boucher@us.logicalis.com'
        $SmtpServer = 'smtp.office365.com'
        $SmtpPort = '587'
        $Attachments = $OutputCSV

        $mailparam = @{
            To = $ToAddress
            From = $FromAddress
            Subject = 'JBT VM Tagging Report'
            Body = "This is a Logicalis VM Tagging report for Managed Services. The following Virtual Machines have changed their status. `n `n `n"+$changelist
            SmtpServer = $SmtpServer
            Port = $SmtpPort
            Credential = $smtpCred
            Attachments = $Attachments
        }

        # Enable the following to send email
        Send-MailMessage @mailparam -UseSSL

    } 
    else 
      { "[Warning]: No ARM VMs found...  Skipping remaining steps."
        $outputLOG = "[Warning]: No ARM VMs found...  Skipping remaining steps."
        Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG} 
}  # Subscriptions 
 
 
"`r`nCompleted!" 
$outputLOG = "`r`nCompleted!"
Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
# Get End Time 
$endDTM = (Get-Date) 
"Stopping Script: {0:yyyy-MM-dd HH:mm}..." -f $endDTM
$outputLOG = "Stopping Script: {0:yyyy-MM-dd HH:mm}..." -f $endDTM
Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG 
 
# Echo Time elapsed 
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"
$outputLOG = "Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"
Add-Content $OutputCSVPath$OutputCSVFile$outputLOGExt $outputLOG
 
# Catch any unexpected error occurring while running the script 
trap { 
    Write-Host "An unexpected error occurred....  Please try again in a few minutes..."   
    Write-Host $("`Exception: " + $_.Exception.Message);  
    Exit 
 } 
 
 