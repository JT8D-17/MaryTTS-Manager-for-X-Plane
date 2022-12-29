# MaryTTS Manager
MaryTTS Manager (abbreviated as MTTSM) is a FlyWithLua-based user interface and manager to control  a [MaryTTS](http://mary.dfki.de/) text-to-speech server from within X-Plane 11.   
It ships as an all-in-one, ready to go package with an implementation of [MaryTTS v5.3 (snapshot)](https://github.com/marytts/marytts) and [Adoptium Eclipse Temurin OpenJDK](https://adoptium.net/temurin/releases?version=18).


&nbsp;

<a name="toc"></a>
## Table of Contents
1. [Compatibility and Requirements](#requirements)
2. [Installation](#install)
3. [Uninstallation](#uninstall)
4. [Functionality](#functionality)
5. [First Start](#first)
6. [User Interface](#UI)
	1. [Main Menu](#mainmenu)
	2. [Server and Interface Menu](#serverinterface)
	3. [UI settings Menu](#uisettings)
7. [Known Issues](#issues)
8. [License](#license)

&nbsp;

<a name="requirements"></a>
## 1 - Compatibility and Requirements

**Compatibility:**

Linux: Development platform; extensively tested   
Windows 10: Works, but has only been tested a little   
MacOS/OSX: Unknown due to a lack of willing and able testers

**Requirements:**

- All: [X-Plane 11](https://www.x-plane.com/) (version 11.50 or higher)
- All: [FlyWithLuaNG](https://forums.x-plane.org/index.php?/files/file/38445-flywithlua-ng-next-generation-edition-for-x-plane-11-win-lin-mac/) (version 2.7.28 or higher)
- Linux: System packages providing the _curl_, _kill_, _ls_ and _pgrep_ commands
- Windows: Any version that provides the _curl_, _dir_, _start_,  _taskkill_ and _tasklist_ commands (Windows 10 or newer)

**Please check and confirm that your system fulfills the operating system specific requirements before installing MTTSM!**

[Back to table of contents](#toc)

&nbsp;

<a name="install"></a>
## 2 - Installation

- Click "Code" --> "Download ZIP" or use [this link](https://github.com/JT8D-17/MaryTTS-Manager-for-X-Plane/archive/refs/heads/main.zip).
- Unzip the archive and copy the "Scripts" and "Modules" folders into _"X-Plane 11/Resources/plugins/FlyWithLua/"_


[Back to table of contents](#toc)

&nbsp;

<a name="uninstall"></a>
## 3 - Uninstallation

- Delete _MaryTTSManager.lua_ from _"X-Plane 11/Resources/plugins/FlyWithLua/Scripts"_
- Delete _"MaryTTSManager"_ from _"X-Plane 11/Resources/plugins/FlyWithLua/Modules"_


[Back to table of contents](#toc)

&nbsp;

<a name="functionality"></a>
## 4 - Functionality

**4.1 - Purpose**

MaryTTS Manager is an interface and wrapper to send strings to a MaryTTS server running on the system.

It is basically a bridge between an X-Plane plugin (or FlyWithLua or XLua or SASL script) and the MaryTTS server and provides equal text to speech capabilities on Linux and Windows (and maybe MacOS) with a defined, consistent range of voices (actors).

It was developed for use with the _SimpleATC_ module of [X-ATC-Chatter](https://www.stickandrudderstudios.com/x-atc-chatter-project/) in close cooperation with [Stick and Rudder studios](https://www.stickandrudderstudios.com/) to provide multiple pilot and controller voices for Linux users.

MaryTTS is a Java application and therefore requires a Java runtime environment (JRE) on the system. Since the capabilities and compaitibility of available JREs vary greatly and would lead to compatibility issues with MaryTTS, a local JRE installation for use by the MaryTTS server is provided by in the MTTSM package by a binary from [Adoptium](https://https://adoptium.net/).

For normalizing volume levels, MaryTTS Manager ships with a standalone FFmpeg binary obtained from [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds/releases).

&nbsp;

**4.2 - Interfaces**

The bridging between plugin and MaryTTS is defined in interface files that can be created and edited directly in MTTSM's user interface in X-Plane. These interfaces define various aspects like input text file location, output WAV file location and optional voice mapping to assign a specific voice to a specific actor. Interface file structure is fixed and the user interface exposes all the required inputs for plugin or script developers.

&nbsp;

**4.3 - Input processing**

The core element is a watchdog loop that runs in one second intervals and monitors a text input file. If a string is written to said input file, MTTSM will read it from file, spllit it into actor and string to be spoken based on a delimiter defined in the interface file.   
The actor is then further converted into an installed MaryTTS voice by means of a voice mappping defined in the interface file or - if none is found - by a random voice selection. There is a small degree of memory for actors, so that e.g. an ATC ground controller will have a consistent voice for all interactions until a switchover to another actor (e.g. ATC tower controller), at which point another (unmapped) voice is randomly chosen.   
Voice and string to be spoken are then sent to the MaryTTS server for processing via HTTP interface. The server will then output a WAV file to a location specified in the interface file.   
Playback of the output WAV file is either done by the plugin itself or by FlyWithLua. After playback, the WAV file is deleted.

[Back to table of contents](#toc)

&nbsp;


<a name="first"></a>
## 5 - First start

MaryTTS Manager must be started manually until the _"Autosave"_ and _"Autoload"_ options in the _"UI Settings"_ window have been enabled.   
After that, the visibility status of the window will be remembered and applied during each script start (or reload).

Start MTTSM...   
...from X-Plane's _"Plugins"_ menu with  _"MaryTTS Manager"_ --> _"Open Window"_    
or    
...from the FlyWithLua menu with _"FlyWithLua"_ --> _"FlyWithLua Macros"_ --> _"MaryTTS Manager: Toggle Window"_    
or    
...by assigning a keyboard shortcut to _"MaryTTS Manager/Window/Toggle Window"_ in X-Plane's keyboard settings window.

Then go into the _"UI Settings"_ menu end enable the _"Autosave"_ and _"Autoload"_ functions.   
Next, start a MaryTTS server (see section 6.2.5).   
Once the server has started, select the _"None/Testing"_ interface and have a voice speak the entered sting (see section 6.2.1 and 6.2.4). If you hear voice output, MaryTTS is ready for use.

[Back to table of contents](#toc)

&nbsp;

<a name="UI"></a>
## 6 - User Interface

General hints:   
**Most, if not all, items have tooltips!**    
After having typed a value into any text/number input box, click anywhere in MTTSM's window to leave it, otherwise it will keep focus, eating up all keyboard inputs (see "Known Issues" section below).   
Undesired values in text/number input boxes that were just entered can be discarded  by pressing the "ESC" key.  
Window size is saved when the "Autosave" option is activated in the _"UI Settings"_ window
The MTTSM window will automatically open upon X-Plane session start if both the "Autosave" and "Autoload" option have been activated in the _"UI Settings"_ menu (see section 6.3.3 below).   

[Back to table of contents](#toc)

&nbsp;
 
<a name="mainmenu"></a>
### 6.1 - Main Menu

Click the _"Server and Interface"_ or _"UI Settings"_ button to enter the respective menu. Each of these menus offers a _"Main Menu"_ button to immediately return.
 
 [Back to table of contents](#toc)
 
 &nbsp;
 
 <a name="serverinterface"></a>
### 6.2 - Server and Interface Menu

**6.2.1 - Interface selector**

The interface selector lists all the available MTTSM interfaces found in `FlyWithLua/Modules/MaryTTSManager/Interfaces` at script startup. Pressing the _"Rescan"_ button rescans that folder and rebuilds the list of available interfaces.   
**Selecting an interface is only necessary for reviewing its settings or for editing. All plugin interfaces stored in the interface folder are automatically processed at X-Plane session start and continuously monitored as long as X-Plane is running!**

&nbsp;

**6.2.2 - Interface settings (non-edit mode)**

This is a multifunction menu which displays various interface information and interaction settings.    
All changes made to the text input and selector boxes **only apply until the next interface rescan or script reload**. For permanent changes to an interface, use "Edit" mode (see below).     
Text input boxes additionally will lose any changes unless in "Edit" mode.

&nbsp;

**6.2.3 - Interface settings (edit mode)**

The edit mode for the interface can be enabled with the _"Enable Edit Mode"_ button. Picking _"Create New Interface"_ from the interface selector will automatically enter edit mode.   
**When in edit mode, the watchdog that scans for input text files for text-to-speech processing is disabled.**   
Changes made in edit mode may be saved to the interface configuration file (existing or new) by pressing the _"Save Interface Configuration File"_ button.   
Disabling edit mode for an existing interface after having made changes will retain these new values until the _"Rescan"_ button next to the interface selector is pressed. This will trigger a complete reload of all available interfaces.

&nbsp;

**6.2.4 - Testing area**

This interface element is **only visible when the _"None/Testing"_ interface is selected and a MaryTTS server is running**.   
The main purpose of this element is to provide a quick method to check that MTTSM is working properly.   
Enter a string that should be spoken, pick a voice and hit the _"Speak"_ button. You should hear the spoken string a few seconds later.

&nbsp;

**6.2.5 - Server controls**

MaryTTS server status is displayed in a string at the top of this UI element. When this string contains a (numerical) process ID, you have a good indicatgion that the server process is up and running.

Pressing _"Check MaryTTS' Process"_ will trigger a system call to find the process ID of the MaryTTS server on the system. **This may cause a short X-Plane stutter on some systems.**   
This button is useful for checking if the server is still running during longer X-Plane sessions or during server startup and shutdown.

The _"Start/Stop MaryTTS server"_ button will trigger the server startup or shutdown process.   
**Even on faster PCs, server startup and shutdown may take a few seconds.**

&nbsp;
 
 [Back to table of contents](#toc)
 
 &nbsp;

<a name="uisettings"></a>
### 6.3 - UI Settings Menu

**6.3.1 - Notification settings**

"Notification display time" accepts integer (i.e. whole number) values and controls the time in seconds, for which notifications in the notification area below the main window content is displayed.

&nbsp;


**6.3.2 - Window hotkey control**

 _"[Enable/Disable] Window Toggling by Hotkey"_ toggles the hotkey activation mode for the main window, independent of which key was set for this in X-Plane's keyboard settings.    
The "Keyboard Key Code" field accepts integer (whole number) values and determines the key that will toggle MTTSM's window status. The default keycode is 85, i.e. "u".    
A key (combination) to toggle the Window may always be set in X-Plane's keyboard settings (_"MaryTTS Manager"_ section).
	
&nbsp;
	
**6.3.3 - Autosave/Autoload**

 _"[Enable/Disable] Autosave"_ saves __MTTSM's UI settings__ settings immediately to file when activated, including window size and position and will then autosave when another setting has been changed. Does not affect the server interface parameters!    
 _"[Enable/Disable] Autoload"_ autoloads all __MTTSM window settings__ upon script start (when starting an X-Plane session). This option may also be toggled from the _"Plugins"_ --> _"MaryTTS Manager"_ --> _"Autoload Settings"_ menu item.

&nbsp;

**6.3.4 - Manual UI settings file management**

The _"Save UI Settings"_, _"Load UI Settings"_ and _"Delete UI Settings"_ buttons are self-explanatory and __only affect MTTSM's UI settings file, not the currently active cloud preset__

&nbsp;
	
**6.3.5 - UI settings file location**

The path to the settings file is: `FlyWithLua/Modules/MaryTTSManager/UI_Prefs.cfg`. Altering it requires editing the script source and is therefore not recommended.    

[Back to table of contents](#toc)


&nbsp;

<a name="issues"></a>
## 7 - Known issues

- There is a slight delay between sending a string to the server and hearing it due to the required processing from text to speech.
- Voice quality may be too low for some people, but this is as good as it gets with MaryTTS.
- MaryTTS still has bugs, especially with [strings with apostrophes](https://github.com/marytts/marytts/issues/817). MTTSM attempts to expand such strings (e.g. "you're" --> "you are") but naturally can't catch all of them (see *MTTSM_PhoneticCorrections* in *Modules/MaryTTSManager/Lua/MTTSM_Main.lua*), so it's best to avoid contractions where possible.
- Text input boxes will not automatically unfocus. Click anywhere inside the UI to unfocus them.
- Checking for the server process may produce system stutters, especially on Windows
- Checking for an input file or playing back an output wave file may slightly degrade simulator performance


[Back to table of contents](#toc)

&nbsp;

<a name="license"></a>
## 8 - License

MaryTTS Manager is licensed under the European Union Public License v1.2 (see _EUPL-1.2-license.txt_). Compatible licenses (e.g. GPLv3) are listed  in the section "Appendix" in the license file.

[MaryTTS license](https://github.com/marytts/marytts/blob/master/LICENSE.md)

[Adoptium license](https://adoptium.net/docs/faq/)

[FFmpeg license](https://www.ffmpeg.org/legal.html)

[Back to table of contents](#toc)