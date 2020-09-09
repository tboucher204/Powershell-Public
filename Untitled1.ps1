$mkvedit = "C:\Program Files\MKVToolNix\mkvpropedit.exe"
$srcFolder = "Y:\Videos\Anime TV\K-On!"
$myfile = ""

$files = Get-ChildItem -Path $srcFolder -Recurse -Filter *.mkv

foreach ($f in $files) {
    #$f.Name
    $myfile = $f.FullName
    #$currentFolder = $f.DirectoryName
    "Working on $myfile"
    $command = $mkvedit $myfile "--edit track:a1 --set flag-default=0 --edit track:a2 --set flag-default=1 --edit track:s1 --set flag-default=0"
    
}