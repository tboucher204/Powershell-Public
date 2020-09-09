# Load (aka "dot-source) the Function 
. E:\nanoserver\Convert-WindowsImage.ps1 
# Prepare all the variables in advance (optional) 
$ConvertWindowsImageParam = @{  
    SourcePath = "E:\nanoserver\nanoserver.wim"  
    Edition    = "CORESYSTEMSERVER_INSTALL"
    VHDPath = "E:\nanoserver\nanoserver.vhd"
    VhdFormat = "VHD"
    VhdPartitionStyle = "MBR"
    Package = @(  
        "E:\nanoserver\Packages\Microsoft-NanoServer-Guest-Package.cab"  
        "E:\nanoserver\Packages\en-us\Microsoft-NanoServer-Guest-Package.cab"  
    ) 
}  
# Produce the images 
$VHDx = Convert-WindowsImage @ConvertWindowsImageParam

md e:\mountdir

dism /Mount-Image /ImageFile:e:\nanoserver\NanoServer.vhd /Index:1 /MountDir:e:\mountdir

dism /image:e:\mountdir /Apply-Unattend:e:\nanoserver\unattend.xml

md e:\mountdir\windows\panther

copy e:\nanoserver\unattend.xml e:\mountdir\windows\panther

dism /Unmount-Image /MountDir:e:\mountdir /Commit

rmdir e:\mountdir