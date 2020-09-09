$jobName = "K-On"
$mkvedit = "C:\Program Files\MKVToolNix\mkvpropedit.exe"
$srcFolder = "\Videos\Anime TV\K-On!\Season 1"


$files = Get-ChildItem -Path $srcFolder -Filter *.mkv

foreach ($f in $files) {
    $f.Name
    #$currentFolder = $f.DirectoryName

    
    
}