# MaryTTS Manager
MaryTTS Manager (abbreviated as MTTSM) FlyWithLua-based user interface  and manager to control  a [MaryTTS](http://mary.dfki.de/) text-to-speech server from within X-Plane 11.   
It ships as an all-in-one, ready to go package with an implementation of [MaryTTS v5.2](https://github.com/marytts/marytts/releases/tag/v5.2) and [AdoptOpenJDK v.11.0.7+10-jre](https://adoptopenjdk.net/).

**LINUX ONLY (for now?)**

&nbsp;

<a name="toc"></a>
## Table of Contents
1. [Requirements](#requirements)
2. [Installation](#install)
3. [Uninstallation](#uninstall)
4. [First Start](#first)
5. [User Interface](#UI)
	1. ["Main" screen](#main)
	2. ["UI settings" screen](#uisettings)
6. [Known Issues](#issues)
7. [License](#license)

&nbsp;

<a name="requirements"></a>
## 1 - Requirements

- [X-Plane 11](https://www.x-plane.com/) (version 11.50 or higher)
- [FlyWithLuaNG](https://forums.x-plane.org/index.php?/files/file/38445-flywithlua-ng-next-generation-edition-for-x-plane-11-win-lin-mac/) (version 2.7.28 or higher)
- Linux with packages providing _curl_, _kill_ and _pgrep_

&nbsp;
[Back to table of contents](#toc)

&nbsp;

<a name="install"></a>
## 2 - Installation

Copy the "Scripts" and "Modules" folders into _"X-Plane 11/Resources/plugins/FlyWithLua/"_

&nbsp;
[Back to table of contents](#toc)

&nbsp;

<a name="uninstall"></a>
## 3 - Uninstallation

- Delete _MaryTTSManager.lua_ from _"X-Plane 11/Resources/plugins/FlyWithLua/Scripts"_
- Delete _"MaryTTSManager"_ from _"X-Plane 11/Resources/plugins/FlyWithLua/Modules"_

&nbsp;
[Back to table of contents](#toc)

&nbsp;

<a name="first"></a>
## 4 - First start

MaryTTS Manager must be started manually until the _"Autosave"_ option in the _"UI Settings"_ window has been enabled.   
After that, the visibility status of the window will be remembered and applied during each script start (or reload).

Start MTTSM...   

1.  ...from X-Plane's _"Plugins"_ menu with
 _"MaryTTS Manager"_ --> _"Open Window"_
or
_"FlyWithLua"_ --> _"FlyWithLua Macros"_ --> _"MaryTTS Manager: Toggle Window"_
2. ...by assigning a keyboard shortcut for 
_"MaryTTS Manager/Window/Toggle Window"_
in X-Plane's keyboard settings window.


&nbsp;
[Back to table of contents](#toc)

&nbsp;

<a name="UI"></a>
## 5 - User Interface

General hints:   
	- All items should have tooltips when they're hovered over with the mouse cursor
	- After having typed a value into any text/number input box, click anywhere in MTTSM's window to leave it, otherwise it will keep focus, eating up all keyboard inputs (see "Known Issues" section below).   
	- Undesired values in text/number input boxes that were just entered can be discarded  by pressing the "ESC" key.  
	- Window size is saved when the "Autosave" option is activated in the _"UI Settings"_ window
 
<a name="main"></a>
###5.1 - "Main" screen

Still empty...

[Back to table of contents](#toc)
<a name="uisettings"></a>
### 5.2 - "UI Settings" screen

**5.2.1 - Navigation**
	- The menu can be accessed with the _"UI Settings"_ button.
	- The _"Back"_ button leads back to the start screen.

**5.2.2 - Notification settings**
	- "Notification display time" accepts integer (i.e. whole number) values and controls the time in seconds, for which notifications in the notification area below the main window content is displayed

**5.2.3 - Window hotkey control**
	- _"[Enable/Disable] Window Toggling by Hotkey"_ toggles the hotkey activation mode for the main window, independent of which key was set for this in X-Plane's keyboard settings 
	- The "Keyboard Key Code" field accepts integer (whole number) values and determines the key that will toggle the MTTSM window's visibility. The default keycode is 85, i.e. "u".
	- A key (combination) to toggle the Window may always be set in X-Plane's keyboard settings (_"MaryTTS Manager"_ section).
	
**5.2.4 - Autosave/Autoload**
	- _"[Enable/Disable] Autosave"_ saves all parameters that may be programmed to be autosaved immediately to file when activated, including window size and position and will then autosave when another setting has been changed. 
Definitely affects all UI settings. Settings from other submodules may have a separate autosave logic or none at all.
	- _"[Enable/Disable] Autoload"_ autoloads all __UI screen settings and submodules__ upon script start (when starting an X-Plane session).  
This option may also be toggled from the _"Plugins"_ --> _"MaryTTS Manager"_ --> _"Autoload Settings"_ menu item.

**5.2.5 - Manual UI settings file management**
	-  The _"Save UI Settings"_, _"Load UI Settings"_ and _"Delete UI Settings"_ buttons are self-explanatory and __only affect the UI setings file, not any submodule settings__
	
**5.2.6 - UI settings file location**
	- The path to the settings file is:   
	 _"FlyWithLua/Modules/MaryTTSManager/UI_Prefs.cfg"_  
	Altering this requires editing the script source and is therefore not recommended.

&nbsp;
[Back to table of contents](#toc)

&nbsp;

<a name="issues"></a>
## 6 - Known issues

None at this time

&nbsp;
<a name="license"></a>
[Back to table of contents](#toc)

&nbsp;

## 7 - License

MaryTTS Manager is licensed under the European Union Public License v1.2 (see _EUPL-1.2-license.txt_). Compatible licenses (e.g. GPLv3) are listed  in the section "Appendix" in the license file.

[MaryTTS license](https://github.com/marytts/marytts/blob/master/LICENSE.md)

[AdoptOpenJDK license](https://adoptopenjdk.net/faq.html?variant=openjdk11&jvmVariant=openj9#licensing)