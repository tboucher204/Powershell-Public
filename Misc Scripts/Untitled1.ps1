Connect-AzAccount

get-azcontext

$credential = Get-Credential
New-PSDrive -Name "Z" -PSProvider "FileSystem" -Root "\\sitelogiqci.file.core.windows.net\sitelogiqci" -Credential $credential
get-psdrive

get-acl -Path "Z:\LogicalisTest" |fl

$adGroup = get-azadgroup -ObjectID 50be2170-8076-4d2b-a268-d29dfb4e6922
get-azadgroup LogicalisCI@sitelogiq.com

$acl = Get-Acl -Path "Z:\LogicalisTest"

$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("tim.boucher@sitelogiq.com","FullControl","Allow")

$acl.SetAccessRule($AccessRule)

$acl | Set-Acl -Path "Z:\LogicalisTest"


Get-AzLoadBalancer | Get-AzLoadBalancerProbeConfig -Name $_.Name | ft Name, Protocol, Port, RequestPath | out-file -FilePath "g:\Healthprobes.txt"
