$r = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$regRoot = "HKCU:\Software\Microsoft\"


$profiles = @{"Netbook" = @("Realtek HD Audio output",      
                            "Realtek HD Audio input");
            "Bluetooth" = @("Bluetooth Hands-free Audio", 
                            "Bluetooth Hands-free Audio") }

function Write-Message ( [string]$message )
{
    echo $message
    # Uncomment this line to show dialog outputs from -set 
    # $r = [System.Windows.Forms.MessageBox]::Show($message)
}

function Set-Mapping ( [string]$devOut, [string]$devIn )
{
    echo "Profile audio:`n  in  = $devIn`n  out = $devOut"

    $regKey = $regRoot + "\Multimedia\Sound Mapper\"
    Set-ItemProperty $regKey -name Playback -value $devOut
    Set-ItemProperty $regKey -name Record -value $devIn
}

function List-Devices
{
    $regKey = $regRoot + "\Windows\CurrentVersion\Applets\Volume Control\"
    echo "Sound devices:"
    ls $regKey | where { ! $_.Name.EndsWith("Options") } | 
        Foreach-Object { 
            echo ("  " + $_.Name.Substring($_.Name.LastIndexOf("\")+1)) 
        }
}

#$cmd = $args[0]
$cmd = "-devices"
switch ($cmd)
{
    "-profiles" 
    {
        echo "Sound profiles:"
        echo $profiles
    }
    "-devices"
    {
        List-Devices
    }
    "-set" 
    {
        $p = $args[1]
        if (!$profiles.ContainsKey($p)) {
            echo "No such profile: $p"
            echo $profiles
            exit
        }
        Set-Mapping $profiles.Get_Item($p)[0] $profiles.Get_Item($p)[1]
        Write-Message "Profile set to: $p"
    }
    default 
    { 
        Write-Message "No such option: $cmd" 
    }
}