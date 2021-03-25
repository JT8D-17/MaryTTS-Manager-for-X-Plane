<# LuATC Speech Output Controller (Windows)

Checks a text file in a given interval
If first line not empty, splits the first line into voice and text
Converts whitespace in text to "%20"
Passes voice and text to MaryTTS server, producing an output file
Plays the output file
Deletes the line from the text file
Repeats

Controls MaryTTS server

Generates a list of available voices

#>

$host.ui.RawUI.WindowTitle = “MaryTTS for X-Plane”
$file = Join-Path "$PSScriptRoot" "TEMP_TaskList.txt"
$wavfile = Join-Path "$PSScriptRoot" "out.wav"
$maryfolder = "$PSScriptRoot\marytts-5.2"
$voicelibfile = "$PSScriptRoot\MaryTTS_Voice_Lib.txt"
$verbose = "true"
$filechange = "false"
$maryserverrunning = "false"

function filemonitor {
    Get-Content $file -First 1 | ForEach-Object {
        if($_) {
            #if($verbose -eq "true"){ Write-Host $(Get-Date -Format "HH:mm:ss") File change detected! }    
            #Write-Host $_
            $voice = $_.Split("::")[0]
            $text = $_.Split("::")[2]
            if($verbose -eq "true"){ Write-Host $(Get-Date -Format "HH:mm:ss") : $voice says `"$text`" }
            $text = [uri]::EscapeUriString("$text")
            # MaryTTS
            Invoke-WebRequest -Uri "127.0.0.1:59125/process?INPUT_TYPE=TEXT&AUDIO=WAVE_FILE&OUTPUT_TYPE=AUDIO&LOCALE=en_US&EFFECT=JetPilot&VOICE=$voice&INPUT_TEXT=`"$text`"" -Method Get -Outfile $wavfile
            # Media player test
            $PlayWav=New-Object System.Media.SoundPlayer
            $PlayWav.SoundLocation=$wavfile
            $PlayWav.playsync()

            $filechange = "true"
        }
    }
    if($filechange -eq "true") {
        #(Get-Content $file) | Where { $_ -notmatch "^::$text" } | Set-Content $file
        $lines = (Get-Content $file | Where-Object {$_.Trim()}).Count
        #Write-Host $lines
        if($lines -eq 1) {
            Clear-Content $file
            $filechange = "false"
        }Else{
            (Get-Content $file | Select-Object -Skip 1) | Set-Content $file
            $filechange = "false"
        }
    }
}

function updatevoicelib {
    if(Test-Path -Path $voicelibfile) {
        Write-Host $(Get-Date -Format "HH:mm:ss") "Old voice library file removed"
        Remove-Item $voicelibfile
    }

    Get-ChildItem "$maryfolder\installed" -Filter voice-* | Foreach-Object {
        $name = (Select-String -Path $_ -Pattern " name=`"(.*)`" type=").Matches.Groups[1].Value
        $name >> $voicelibfile
        Write-Host $(Get-Date -Format "HH:mm:ss") "$name added to voice library file"
    }
}


function watchdog($interval) {
while ($true) {
    sleep $interval
    <# Check for X-Plane #>
    if(Get-Process -name "X-Plane" -ErrorAction SilentlyContinue){
        <# Check for MaryTTS javaw process (size > 200 Mb) #>
        if(Get-Process -name "javaw" -ErrorAction SilentlyContinue | Where-Object {$_.WorkingSet -gt 200000000}) {
            if($maryserverrunning -eq "false"){
                $SEL = Select-String -Path "$maryfolder\log\server.log" -Pattern "marytts.server Waiting for client to connect"
                if($SEL -ne $null){
                    Write-Host $(Get-Date -Format "HH:mm:ss") "MaryTTS Server has started up."
                    updatevoicelib
                    if(-not(Test-Path -Path "$file")) { New-Item -Path $file }
                    $maryserverrunning = "true"
                }
            }Else{
                if(Test-Path -Path "$file"){
                    filemonitor
                }
            }
        }Else{
            if(-Not(Get-Process -name "javaw" -ErrorAction SilentlyContinue)){
                Write-Host $(Get-Date -Format "HH:mm:ss") "Starting MaryTTS Server"
                if(Test-Path -Path "$maryfolder\log\server.log") {
                    Write-Host $(Get-Date -Format "HH:mm:ss") "Removing old MaryTTS Server.log"
                    Remove-Item "$maryfolder\log\server.log"
                }
                javaw -showversion -Xms40m -Xmx1g -cp "$maryfolder\lib\*" "-Dmary.base=$maryfolder" marytts.server.Mary
            }
        }
    }Else{
        <# Check for MaryTTS javaw process (size > 200 Mb) #>
        if(Get-Process -name "javaw" -ErrorAction SilentlyContinue | Where-Object {$_.WorkingSet -gt 200000000}){
            Write-Host $(Get-Date -Format "HH:mm:ss") "X-Plane quit. Stopping MaryTTS Server."
            $marypid = (Get-Process -name "javaw" | Where-Object {$_.WorkingSet -gt 200000000}).Id
            #Write-Host $marypid
            Stop-Process -id $marypid
            $maryserverrunning = "false"
            Remove-Item "$file"
            exit
        }
    } 
}
}

watchdog 1
