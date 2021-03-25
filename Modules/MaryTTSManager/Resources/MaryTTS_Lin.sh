#! /bin/bash

# LuATC Speech Output Controller
#
# Checks a text file in a given interval
# If first line not empty, splits the first line into voice and text
# Converts whitespace in text to "%20"
# Passes voice and text to MaryTSS server, producing an output file
# Plays the output file
# Deletes the line from the text file
# Repeats
#
# Controls MaryTTS server
# 
# Generates a list of available voices
#
#

scriptdir="$(cd "$(dirname "$0")" && pwd)"
file="$scriptdir/TEMP_TaskList.txt"
wavfile="$scriptdir/out.wav"
#maryfolder="$scriptdir/marytts-5.2"
maryfolder="$scriptdir/marytts-5.3"
jrefolder="$scriptdir/JRE/Linux/jdk-11.0.7+10-jre/bin/"
voicelibfile="$scriptdir/MaryTTS_Voice_Lib.txt"
logfile="$scriptdir/LOG_MaryTTS.txt"
verbose=true
filechange=false
maryserverrunning=false



#function filemonitor {
    #Get-Content $file -First 1 | ForEach-Object {
        #if($_) {
            ##if($verbose -eq "true"){ Write-Host $(Get-Date -Format "HH:mm:ss") File change detected! }    
            ##Write-Host $_
            #$voice = $_.Split("::")[0]
            #$text = $_.Split("::")[2]
            #if($verbose -eq "true"){ Write-Host $(Get-Date -Format "HH:mm:ss") : $voice says `"$text`" }
            #$text = [uri]::EscapeUriString("$text")
            ## MaryTTS
            #Invoke-WebRequest -Uri "127.0.0.1:59125/process?INPUT_TYPE=TEXT&AUDIO=WAVE_FILE&OUTPUT_TYPE=AUDIO&LOCALE=en_US&EFFECT=JetPilot&VOICE=$voice&INPUT_TEXT=`"$text`"" -Method Get -Outfile $wavfile
            ## Media player test
            #$PlayWav=New-Object System.Media.SoundPlayer
            #$PlayWav.SoundLocation=$wavfile
            #$PlayWav.playsync()

            #$filechange = "true"
        #}
    #}
    #if($filechange -eq "true") {
        ##(Get-Content $file) | Where { $_ -notmatch "^::$text" } | Set-Content $file
        #$lines = (Get-Content $file | Where-Object {$_.Trim()}).Count
        ##Write-Host $lines
        #if($lines -eq 1) {
            #Clear-Content $file
            #$filechange = "false"
        #}Else{
            #(Get-Content $file | Select-Object -Skip 1) | Set-Content $file
            #$filechange = "false"
        #}
    #}
#}

#function updatevoicelib {
    #if(Test-Path -Path $voicelibfile) {
        #Write-Host $(Get-Date -Format "HH:mm:ss") "Old voice library file removed"
        #Remove-Item $voicelibfile
    #}

    #Get-ChildItem "$maryfolder\installed" -Filter voice-* | Foreach-Object {
        #$name = (Select-String -Path $_ -Pattern " name=`"(.*)`" type=").Matches.Groups[1].Value
        #$name >> $voicelibfile
        #Write-Host $(Get-Date -Format "HH:mm:ss") "$name added to voice library file"
    #}
#}

function updatevoicelib() {
	if [ -f "$voicelibfile" ]; then
		echo $(date +"%T")": Old voice library file removed" | tee -a "$logfile"
		rm "$voicelibfile"
	fi
	

}

function watchdog () {
while true; do
	sleep $1
	# Check for X-Plane's process
	if pgrep -f "X-Plane-x86_64" >/dev/null; then
		# Check for MaryTTS process
		if [ pgrep -f "marytts.server.Mary" >/dev/null ]; then
			if [ "$maryserverrunning" == "false" ]; then
				if grep -q "marytts.server Waiting for client to connect" "$maryfolder/log/server.log" -R; then
					echo $(date +"%T")": MaryTTS Server has started up (PID "$(pgrep -f "marytts.server.Mary")")" | tee -a "$logfile"
					#updatevoicelib
					if [ ! -f "$file" ]; then
						touch "$file"
					fi
					maryserverrunning=true
				fi
			else
				if [ -f "$file" ]; then
					#filemonitor
					sleep 1
				fi
			fi
		else
			if [ ! pgrep -f "marytts.server.Mary" >/dev/null ]; then
				echo $(date +"%T")": Starting MaryTTS Server" | tee -a "$logfile"
				if [ -f "$maryfolder/log/server.log" ]; then
					echo $(date +"%T")": Removing old MaryTTS Server.log" | tee -a "$logfile"
					rm "$maryfolder/log/server.log"
				fi
				rm "$logfile"
				nohup "$jrefolder/java" -showversion -Xms40m -Xmx1g -cp "$maryfolder/lib/*" -Dmary.base="$maryfolder" $* marytts.server.Mary >> "$logfile" &
			fi
		fi
	else 
		# Check for MaryTTS process
		if pgrep -f "marytts.server.Mary" >/dev/null; then
			echo $(date +"%T")": X-Plane quit. Stopping MaryTTS Server." | tee -a "$logfile"
			kill $(pgrep -f "marytts.server.Mary")
			maryserverrunning=false
			rm "$file"
			exit
		fi
	fi
done
}

# watchdog "1"

function startmary() {

if ! pgrep -f "marytts.server.Mary" >/dev/null; then
    echo $(date +"%T")": Starting MaryTTS Server" | tee -a "$logfile"
    if [ -f "$maryfolder/log/server.log" ]; then
        echo $(date +"%T")": Removing old MaryTTS Server.log" | tee -a "$logfile"
        rm "$maryfolder/log/server.log"
    fi
    rm "$logfile"
    nohup "$jrefolder/java" -showversion -Xms40m -Xmx1g -cp "$maryfolder/lib/*" -Dmary.base="$maryfolder" $* marytts.server.Mary >> "$logfile" &
fi

}

# startmary

function maryspeak() {
    # curl -o $wavfile -G "http://localhost:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&EFFECT=JetPilot&VOICE=voice-dfki-spike-hsmm-5.2-component&" --data-urlencode "INPUT_TEXT=$1" | aplay
    # curl -s -o $wavfile -G "http://localhost:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&INPUT_TEXT=Hello."
    str=$@
    TEXT=${str// /%20}
    echo $TEXT
    #REMOTE PLAYBACK
    #curl "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_GB&AUDIO=WAVE_FILE&VOICE=dfki-spike-hsmm&INPUT_TEXT="$TEXT | PULSE_SERVER=192.168.1.100 aplay -q
    #LOCAL PLAYBACK
    curl -o $wavfile "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_GB&AUDIO=WAVE_FILE&VOICE=dfki-spike-hsmm&INPUT_TEXT="$TEXT
}


maryspeak "Hello, how are you doing?"
