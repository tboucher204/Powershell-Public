#location of starting directory
$_sourcePath ="C:\Users\dotnet-helpers\Desktop\SourcePath"
#location where files will be copied to 
$_destinationPath="F:\MkvmergeTemp";
#Array of extension that need to move from source path
$_FileType= @("*html*", "*.*txt")
 
Get-ChildItem -recurse ($_sourcePath) -include ($_FileType) | move-Item -Destination ($destination)