$rootfolder = "D:\ServerFolders\Company\Audiobooks"

Function Extract-String {
    Param(
        [Parameter(Mandatory=$true)][string]$string
        , [Parameter(Mandatory=$true)][char]$character
        , [Parameter(Mandatory=$false)][ValidateSet("Right","Left")][string]$range
        , [Parameter(Mandatory=$false)][int]$afternumber
        , [Parameter(Mandatory=$false)][int]$tonumber
    )
    Process
    {
        [string]$return = ""

        if ($range -eq "Right")
        {
            $return = $string.Split("$character")[($string.Length - $string.Replace("$character","").Length)]
        }
        elseif ($range -eq "Left")
        {
            $return = $string.Split("$character")[0]
        }
        elseif ($tonumber -ne 0)
        {
            for ($i = $afternumber; $i -le ($afternumber + $tonumber); $i++)
            {
                $return += $string.Split("$character")[$i]
            }
        }
        else
        {
            $return = $string.Split("$character")[$afternumber]
        }

        return $return
    }
}

ForEach($File in (GCI $rootfolder -Folder)){
$bookname = Extract-String -string $File -character "-" -range Left
$booknametrim = $bookname.trim()
$authornametemp = Extract-String -string $File -character "-" -range Right
$authorname = Extract-String -string $authornametemp -character "_" -range Left
$authornametrim = $authorname.trim()

if (!(Test-Path -Path "$rootfolder\$authornametrim\$booknametrim")) {
    $newpath = New-Item -ItemType directory -Path "$rootfolder\$authornametrim\$booknametrim"
}else{
    $newpath = "$rootfolder\$authornametrim\$booknametrim"
}
#move-item -path $File.FullName -destination $newpath
#$File
#$bookname.trim()
#$authorname.trim()
}