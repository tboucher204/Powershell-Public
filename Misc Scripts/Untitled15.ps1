Connect-AzAccount

set-azcontext -SubscriptionId "d3b361f1-06c2-4214-9b1d-764436e8c02c"

$vm = get-azvm -name azulq02db01

$vm.StorageProfile.Datadisks

$vm.OSProfile