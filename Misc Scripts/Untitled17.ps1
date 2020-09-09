#Provide the subscription Id of the subscription where snapshot exists
$sourceSubscriptionId='d3b361f1-06c2-4214-9b1d-764436e8c02c'

#Provide the name of your resource group where snapshot exists
$sourceResourceGroupName='rg-sap-image-rwu2'

#Provide the name of the snapshot
$imageName='SAP_GoldImg'

#Set the context to the subscription Id where snapshot exists
Select-AzSubscription -SubscriptionId $sourceSubscriptionId

#Create a snapshot from managed disk
$region = 'westus2'
$disk = "/subscriptions/d3b361f1-06c2-4214-9b1d-764436e8c02c/resourceGroups/RG-SAP-IMAGE-RWU2/providers/Microsoft.Compute/disks/azulgold01-os-disk"
$snapshot = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $region
$snapshotName = $imageName + "-" + $region + "-snap"

#Get the source snapshot
$snapshot= Get-AzSnapshot -ResourceGroupName $sourceResourceGroupName -Name $snapshotName

#Provide the subscription Id of the subscription where snapshot will be copied to
#If snapshot is copied to the same subscription then you can skip this step
$targetSubscriptionId='cf0baac3-27bd-4d40-967b-347f305bbb41'

#Name of the resource group where snapshot will be copied to
$targetResourceGroupName='rg-sap-image-rwu2'

#Set the context to the subscription Id where snapshot will be copied to
#If snapshot is copied to the same subscription then you can skip this step
Select-AzSubscription -SubscriptionId $targetSubscriptionId

#We recommend you to store your snapshots in Standard storage to reduce cost. Please use Standard_ZRS in regions where zone redundant storage (ZRS) is available, otherwise use Standard_LRS
#Please check out the availability of ZRS here: https://docs.microsoft.com/en-us/Az.Storage/common/storage-redundancy-zrs#support-coverage-and-regional-availability
$snapshotConfig = New-AzSnapshotConfig -SourceResourceId $snapshot.Id -Location $snapshot.Location -CreateOption Copy -SkuName Standard_LRS

#Create a new snapshot in the target subscription and resource group
New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $targetResourceGroupName 