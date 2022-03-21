$srcFolder = "Y:\Audiobooks\Christopher G. Nuttall"

$files = Get-ChildItem -Path $srcFolder -Recurse -Filter *.m4b

Function WriteToOpfFile ($message) {
    $message
    $opffilepath
    Add-content -LiteralPath $opffilepath -value $message
}

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

foreach ($f in $files) {
    $mypath = $f.Directory.FullName
    
    if ((Get-ChildItem -LiteralPath $mypath -force | Where-Object Extension -in ('.opf') | Measure-Object).Count -eq 0) {
        $tempauthor = $mypath.replace("Y:\Audiobooks\","")
        $tempauthorshort =  Extract-String -string $tempauthor -character "\" -range Left
        $tempauthorshorter = Extract-String -string $tempauthorshort -character "&" -range Left
        $tempauthorshorterer = Extract-String -string $tempauthorshorter -character " " -range Right

        $myfile = $f.Name
        $tempbook = Extract-String -string $myfile -character "(" -range Left
        $tempbooktrim = $tempbook.Trim()
        $tempbookclean = $tempbooktrim.replace(" ", "+")

        $testResult = (Invoke-RestMethod -Uri "https://openlibrary.org/search.json?author=$tempauthorshort&title=$tempbookclean")
        $testResult | Get-Member
        if ($testResult.num_found -eq 1) {
            $book = $testResult.docs

            $book
            $mybook = Extract-String -string $book.key -character "/" -range Right -afternumber 2
            $mybooktitle = $book.title
            $mybookauthor = $book.author_name

            # $opffilepath = "Y:\Audiobooks\Christopher G. Nuttall\Ark Royal\2014 - The Nelson Touch  [Ark Royal 2]\$mybooktitle.opf"
            $opffilepath = "$mypath\$mybooktitle.opf"
    
            # if (Test-Path -LiteralPath $opffilepath) {
            #     Remove-Item -LiteralPath $opffilepath
            # }

            WriteToOpfFile "<?xml version=`"1.0`"  encoding=`"UTF-8`"?>"
            WriteToOpfFile "<package version=`"2.0`" xmlns=`"http://www.idpf.org/2007/opf`" >"
            WriteToOpfFile "`t<metadata xmlns:dc=`"http://purl.org/dc/elements/1.1/`" xmlns:opf=`"http://www.idpf.org/2007/opf`">"
            WriteToOpfFile "`t`t<dc:title>$mybooktitle</dc:title>"
            WriteToOpfFile "`t`t<dc:language></dc:language>"
            WriteToOpfFile "`t`t<dc:identifier scheme=`"OpenLibrary`">$mybook</dc:identifier>"
            WriteToOpfFile "`t`t<dc:creator opf:file-as=`"$mybookauthor`" opf:role=`"aut`">$mybookauthor</dc:creator>"
            WriteToOpfFile "`t</metadata>"
            WriteToOpfFile "</package>"
        }
    }
}
