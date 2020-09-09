$NewObj = $OldObj = Get-DnsServerResourceRecord -Name "Host01" -ZoneName "contoso.com" -RRType "A"
$NewObj.TimeToLive = [System.TimeSpan]::FromHours(2)
Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName "contoso.com" -PassThru