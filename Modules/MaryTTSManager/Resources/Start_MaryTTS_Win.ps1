$host.ui.RawUI.WindowTitle = �MaryTTS for X-Plane�
$JavaPath = "$PSScriptRoot\JRE\Windows\jdk-11.0.7+10-jre\bin\javaw.exe"
$MaryFolder = "$PSScriptRoot\marytts-5.2"

Start-Process $JavaPath -ArgumentList "-showversion -Xms40m -Xmx1g -cp `"$MaryFolder\lib\*`" -Dmary.base=`"$MaryFolder`" marytts.server.Mary" -NoNewWindow