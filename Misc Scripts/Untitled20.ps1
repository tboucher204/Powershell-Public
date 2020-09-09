#Variables
$region = "westus2"
$imageName = "SAP_GoldImg"
$resourceGroupName = "rg-sap-image-rwu2"
$targetSubscriptionId = "cf0baac3-27bd-4d40-967b-347f305bbb41"
#Create a snapshot from managed disk
$disk = "/subscriptions/d3b361f1-06c2-4214-9b1d-764436e8c02c/resourceGroups/RG-SAP-IMAGE-RWU2/providers/Microsoft.Compute/disks/azulgold01-os-disk"
$snapshot = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $region
$snapshotName = $imageName + "-" + $region + "-snap"
New-AzSnapshot -ResourceGroupName $resourceGroupName -Snapshot $snapshot -SnapshotName $snapshotName

#copy the snapshot to another subscription, same region
$snap = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

#change to the target subscription
Select-AzSubscription -SubscriptionId $targetSubscriptionId
$snapshotConfig = New-AzSnapshotConfig -OsType Linux `
                                            -Location $region `
                                            -CreateOption Copy `
                                            -SourceResourceId $snap.Id
$snap = New-AzSnapshot -ResourceGroupName $resourceGroupName `
                            -SnapshotName $snapshotName `
                            -Snapshot $snapshotConfig