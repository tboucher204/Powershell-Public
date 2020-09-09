powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command {$ie = new-object -com "InternetExplorer.Application"
$ie.visible = $FALSE
$vars = 0
while ($vars -ne 6) {$ie.navigate("http://creativitygames.net/random-word-generator/randomwords/5")
while ($ie.Busy -eq "TRUE") {}
start-sleep 5
$doc = $ie.document 
$name = $doc.getElementByID("randomwordslist")
$name = $name.innerHTML
$name = $name.Replace("<li id=`"randomword_1`" style=`"left: 0px; top: 0px; position: relative;`">", "").Replace("</li><br><li id=`"randomword_2`" style=`"left: 0px; top: 0px; position: relative;`">", "  ").Replace("</li><br><li id=`"randomword_3`" style=`"left: 0px; top: 0px; position: relative;`">", "  ").Replace("</li><br><li id=`"randomword_4`" style=`"left: 0px; top: 0px; position: relative;`">", "  ").Replace("</li><br><li id=`"randomword_5`" style=`"left: 0px; top: 0px; position: relative;`">", "  ").Replace("</li><br>", "") -split "  ", 0, "simplematch"
start-sleep 5
$ie1 = "http://www.bing.com/search?q=What+is+a+" + $name[0]
$ie2 = "http://www.bing.com/search?q=What+is+a+" + $name[1]
$ie3 = "http://www.bing.com/search?q=What+is+a+" + $name[2]
$ie4 = "http://www.bing.com/search?q=What+is+a+" + $name[3]
$ie5 = "http://www.bing.com/search?q=What+is+a+" + $name[4]
$ie.navigate($ie1)
while ($ie.Busy -eq "TRUE") {}
$ie.navigate($ie2)
while ($ie.Busy -eq "TRUE") {}
$ie.navigate($ie3)
while ($ie.Busy -eq "TRUE") {}
$ie.navigate($ie4)
while ($ie.Busy -eq "TRUE") {}
$ie.navigate($ie5)
while ($ie.Busy -eq "TRUE") {}
$vars = $vars + 1
$vars}
$ie.Quit();
exit}