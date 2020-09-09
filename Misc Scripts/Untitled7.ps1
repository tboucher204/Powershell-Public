New-ScheduledTask -Name Test -ScriptBlock { start-process 'C:\Program Files\Internet Explorer\iexplore.exe' } -Credential theboucher6\Tim -Authentication CredSSP -RunNow

get-help New-ScheduledTask -examples