Get-ChildItem -Filter “*_*” | Rename-Item -NewName {$_.name -replace ‘_’,’ - ’ }

