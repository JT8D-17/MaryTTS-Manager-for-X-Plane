@echo off

set BASEFOLDER=%~dp0
set JAVAEXEC=%BASEFOLDER%JRE\Windows\jdk-11.0.7+10-jre\bin\java.exe
set MARYFOLDER=%BASEFOLDER%marytts-5.2

echo %MARYFOLDER%

start /b "MaryTTSWindow" "%JAVAEXEC%"  -showversion -Xms40m -Xmx1g -cp "%MARYFOLDER%\lib\*" -Dmary.base="%MARYFOLDER%" marytts.server.Mary