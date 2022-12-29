$host.ui.RawUI.WindowTitle = “MaryTTS for X-Plane”
$JavaPath = "$PSScriptRoot\JRE\Windows\jdk-19.0.1+10-jre\bin\javaw.exe"
$MaryFolder = "$PSScriptRoot\marytts-5.3"

# Start-Process $JavaPath -ArgumentList "-showversion -Xms40m -Xmx1g -cp `"$MaryFolder\lib\*`" -Dmary.base=`"$MaryFolder`" marytts.server.Mary" -NoNewWindow
Start-Process $JavaPath -ArgumentList "-classpath `"$MaryFolder\lib\*`" -Dmary.base=`"$MaryFolder`" marytts.server.Mary" -NoNewWindow
