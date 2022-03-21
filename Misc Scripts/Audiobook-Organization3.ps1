$rootfolder = "Y:\Audiobooks\Clive Cussler\Isaac Bell"

Function Extract-String {
    Param(
        [Parameter(Mandatory = $true)][string]$string
        , [Parameter(Mandatory = $true)][char]$character
        , [Parameter(Mandatory = $false)][ValidateSet("Right", "Left")][string]$range
        , [Parameter(Mandatory = $false)][int]$afternumber
        , [Parameter(Mandatory = $false)][int]$tonumber
    )
    Process {
        [string]$return = ""

        if ($range -eq "Right") {
            $return = $string.Split("$character")[($string.Length - $string.Replace("$character", "").Length)]
        }
        elseif ($range -eq "Left") {
            $return = $string.Split("$character")[0]
        }
        elseif ($tonumber -ne 0) {
            for ($i = $afternumber; $i -le ($afternumber + $tonumber); $i++) {
                $return += $string.Split("$character")[$i]
            }
        }
        else {
            $return = $string.Split("$character")[$afternumber]
        }

        return $return
    }
}

ForEach ($Folder in (GCI $rootfolder |  Where-Object { $_.PSIsContainer -eq 1 })) {

    $newpath = $Folder.FullName
    $newpath

    ForEach ($File in (GCI $newpath -Recurse |  Where-Object { $_.PSIsContainer -eq 0 })) {
        
        if (!(Test-Path -Path "$newpath\$File")) {
            $myfile = $File.FullName
            "$myfile would be moved to $newpath\$File"
            move-item -path $myfile -destination "$newpath\$File"
        }
        else {

        }
        
    }
}