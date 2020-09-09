$jobName = "Buffy"
$srcFolder = "F:\temp\Season 2"
$jobFolder = "F:\MkvmergeTemp\Completed\$jobName"

$files = Get-ChildItem -Path $srcFolder -Filter *.mkv

foreach ($f in $files) {
    #$f.Name
    $currentFolder = $f.DirectoryName

    $workFolder = "$jobFolder\$($f.Directory.Name)"

    If(!(test-path $workFolder))
    {
        New-Item -ItemType Directory -Force -Path $workFolder
    }

    Move-item –path $f.FullName –destination $workFolder
}