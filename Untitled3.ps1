$mkvedit = "C:\Program Files\MKVToolNix\mkvpropedit.exe"
$srcFolder = "Y:\Videos\Anime TV\Sailor Moon\Season 3"
$myfile = ""
$myfilesize = ""
$count = 1

$files = Get-ChildItem -Path $srcFolder -Recurse -Filter *.mkv

foreach ($f in $files) {
    $myfullpath = $f.FullName
    $myfile = $f.Name
    $mynewfile = $myfile -replace 'S01', 'S02'
    #$currentFolder = $f.DirectoryName
    $myfilesize = {{0:0},(Get-Item $myfullpath).length/1MB)}  
    "$myfile = $myfilesize"  
 
    $count++
    
}
 
    

