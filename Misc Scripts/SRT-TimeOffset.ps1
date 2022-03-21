$filePath = 'Y:\Videos\Movies\Star Trek Kirk Collection\Star Trek V - The Final Frontier (1989)\Star Trek V - The Final Frontier (1989).eng.forced.srt'
$timeoffset = '+1000'   #This offset is in Milliseconds (1000 milliseconds = 1 second)

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

$content = Get-Content $filePath
$content | 
  ForEach-Object { 
    
     if($_ -like '*-->*') {
        #Convert time to seconds
        $newstring = $_
        $fromtime = Extract-String -string $newstring -character " " -range Left
        #$fromtime
        $textReformat1 = $fromtime -replace ",","."
        $seconds1 = ([TimeSpan]::Parse($textReformat1)).TotalMilliseconds + $timeoffset
        #$seconds1

        #Convert time back to srt
        #$s = "7000.6789"
        $ts1 =  [timespan]::frommilliseconds($seconds1)
        #("{0:hh\:mm\:ss\,fff}" -f $ts)
        #$ts1.ToString("hh\:mm\:ss\,fff")

        #Convert time to seconds
        $totime = Extract-String -string $newstring -character " " -range Right
        #$totime
        $textReformat2 = $totime -replace ",","."
        $seconds2 = ([TimeSpan]::Parse($textReformat2)).TotalMilliseconds + $timeoffset
        #$seconds2
        
        #Convert time back to srt
        $ts2 =  [timespan]::frommilliseconds($seconds2)
        #("{0:hh\:mm\:ss\,fff}" -f $ts)
        #$ts2.ToString("hh\:mm\:ss\,fff")

        $newstring = $newstring -replace $totime,$ts2.ToString("hh\:mm\:ss\,fff")
        $newstring -replace $fromtime,$ts1.ToString("hh\:mm\:ss\,fff")
     } else {
        $_
     }
  } | 
  Set-Content $filePath