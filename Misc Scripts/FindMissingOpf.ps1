$a = Get-ChildItem Y:\Audiobooks -recurse | Where-Object {$_.PSIsContainer -eq $True}
$b = $a | Where-Object {$_.GetFiles().Count -ne 0} | Select-Object FullName

foreach ($line in $b)
{
    $path = $line.FullName
    # Write-Host $path -NoNewline
    $testObject = Test-Path -Path $path
    if ($testObject)
    {
        # $folder = Get-Item -Path $path
        # $filesCount = $folder.GetFiles().Count
        $filesCount = (Get-ChildItem -Path $path -force | Where-Object Extension -in ('.opf') | Measure-Object).Count
        if ($filesCount.Equals(0))
        {
            #Write-Host "$path - Missing OPF file"
            Write-Host "$path"
        }
        else
        {
            # Write-Host "$path - Contains OPF file"
        }
    }
    else
    {
        Write-Host "$path - Invalid path"
    }
}

# $a = Get-ChildItem Y:\Audiobooks -recurse -Filter "Robert Jordan - *" | Where-Object { $_.PSIsContainer -eq $True }
# # $a | rename-item -newname {$_.name -replace '\]',''}
# $a | rename-item -newname { $_.name -replace 'Robert Jordan - ', '' }