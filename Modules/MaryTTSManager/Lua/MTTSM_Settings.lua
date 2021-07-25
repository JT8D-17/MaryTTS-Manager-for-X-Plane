--[[

Lua Module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

VARIABLES (global and local!)

]]
local MTTSM_SettingsFile = MODULES_DIRECTORY.."MaryTTSManager/UI_Prefs.cfg"   -- Preferences file path
local MTTSM_PageTitle = "UI Settings"
MTTSM_Settings = {
    {"AutoSave",0},             -- Autosave enabled
    {"AutoLoad",0},             -- Autoload enabled
    {"WindowToggleByHotkey",0}, -- Window open/close by hotkey enabled
    {"WindowToggleHotkey",85},  -- Window open/close hotkey (default: 85 = u)
    {"WindowIsOpen",1},         -- Window open/close status
    {"Window_X",100},           -- Window X position
    {"Window_Y",400},           -- Window Y position
    {"Window_W",530},           -- Window width
    {"Window_H",600},           -- Window height
    {"Window_Page",0},          -- Window page
    {"NotificationDispTime",6}, -- Notification display time
    {"AutostartServer",0}       -- MTTSM-SPECIFIC: Auto start the server upon simulator start?
}
local MTTSM_PageInitStatus = 0       -- Has the module been initialized?
--[[

FUNCTIONS

]]
--[[ Accessor: Get name of a setting ]]
function MTTSM_SettingsNameGet(item)
    for i=1,#MTTSM_Settings do
       if MTTSM_Settings[i][1] == item then return MTTSM_Settings[i][1] end
    end
end
--[[ Accessor: Get value of a setting ]]
function MTTSM_SettingsValGet(item)
    for i=1,#MTTSM_Settings do
       if MTTSM_Settings[i][1] == item then return MTTSM_Settings[i][2] end
    end
end
--[[ Accessor: Set value of a setting ]]
function MTTSM_SettingsValSet(item,newvalue)
    for i=1,#MTTSM_Settings do
       if MTTSM_Settings[i][1] == item then MTTSM_Settings[i][2] = newvalue break end
    end
end
--[[ Update window position information ]]
function MTTSM_GetWindowInfo()
		if MTTSM_SettingsValGet("Window_W") ~= imgui.GetWindowWidth() or MTTSM_SettingsValGet("Window_H") ~= imgui.GetWindowHeight() or MTTSM_SettingsValGet("Window_X") ~= MTTSM_Window_Pos[1] or MTTSM_SettingsValGet("Window_Y") ~= MTTSM_Window_Pos[2] then
			MTTSM_SettingsValSet("Window_W",imgui.GetWindowWidth())
			MTTSM_SettingsValSet("Window_H",imgui.GetWindowHeight())
			MTTSM_SettingsValSet("Window_X",MTTSM_Window_Pos[1])
			MTTSM_SettingsValSet("Window_Y",MTTSM_Window_Pos[2])
            --print(MTTSM_SettingsValGet("Window_X")..","..MTTSM_SettingsValGet("Window_Y")..","..MTTSM_SettingsValGet("Window_W")..","..MTTSM_SettingsValGet("Window_H"))
			--MTTSM_Settings_CheckAutosave("NoLog")
		end
end
--[[ Settings file write ]]
function MTTSM_SettingsFileWrite(log)
    MTTSM_Log_Write("FILE INIT WRITE: "..MTTSM_SettingsFile)
    local file = io.open(MTTSM_SettingsFile, "w")
    file:write(MTTSM_ScriptName.." settings file created/updated on ",os.date("%x, %H:%M:%S"),"\n\n")
    for a=1,#MTTSM_Settings do
        --print(MTTSM_Settings[a][1].."="..MTTSM_Settings[a][2])
        file:write(MTTSM_Settings[a][1].."="..MTTSM_Settings[a][2].."\n")
    end
    if file:seek("end") > 0 then 
        if log == "log" then MTTSM_Notification("FILE WRITE SUCCESS: "..MTTSM_SettingsFile,"Success","log") else MTTSM_Notification("FILE WRITE SUCCESS: "..MTTSM_SettingsFile,"Success") end
    else 
        if log == "log" then MTTSM_Notification("FILE WRITE ERROR: "..MTTSM_SettingsFile,"Error","log") else MTTSM_Notification("FILE WRITE ERROR: "..MTTSM_SettingsFile,"Error") end 
    end
	file:close()
end
--[[ Settings file read ]]
function MTTSM_SettingsFileRead()
    local file = io.open(MTTSM_SettingsFile, "r")
    if file then
        MTTSM_Log_Write("FILE INIT READ: "..MTTSM_SettingsFile)
        local i = 0
        local temptable = { }
        for line in file:lines() do
            if string.match(line,"^AutoLoad") then
               MTTSM_Settings_LineSplit(line,"([^=]+)")
               if tonumber(MTTSM_Settings_LineSplitResult[2]) == 0 then 
                   --print("Aborting!")
                   break
               end
            end
            if string.match(line,"^[A-Z,a-z].+=") then
                MTTSM_Settings_LineSplit(line,"([^=]+)")
                temptable[#temptable+1] = MTTSM_Settings_LineSplitResult
                --print(#temptable..": "..table.concat(temptable[#temptable],","))
                i = i+1
            end
            for j=1,#temptable do
                for k=1,#MTTSM_Settings do   
                    if temptable[j][1] == MTTSM_Settings[k][1] then 
                        --print("Match temptable "..temptable[j][1].." with Settings table "..MTTSM_Settings[k][1].." at "..k)
                        MTTSM_Settings[k][2] = tonumber(temptable[j][2]) -- Current value(s)
                    end
                end
            end       
        end
        file:close()
        --for l=1,#MTTSM_Settings do print(table.concat(MTTSM_Settings[l],": ")) end
		if i ~= nil and i > 0 then MTTSM_Notification("FILE READ SUCCESS: "..MTTSM_SettingsFile,"Success","log") else MTTSM_Notification("FILE READ ERROR: "..MTTSM_SettingsFile,"Error","log") end
    else
        MTTSM_Notification("FILE NOT FOUND: "..MTTSM_SettingsFile,"Error","log")
		--MTTSM_Check_AutoLoad = false
	end   
end
--[[ Settings file delete ]]
function MTTSM_SettingsFileDelete()
   os.remove(MTTSM_SettingsFile) MTTSM_Notification("FILE DELETE: "..MTTSM_SettingsFile,"Warning") 
end
--[[ Check Autosave status ]]
function MTTSM_Settings_CheckAutosave(log)
    if MTTSM_SettingsValGet("AutoSave") == 1 then
        if log == "log" then MTTSM_SettingsFileWrite("log")
        else MTTSM_SettingsFileWrite() end
    end
end
--[[ Determine string from value ]]
function MTTSM_ValToStr(input)
    local string = ""
        if input == 0 then string = "Enable" 
        elseif input == 1 then string = "Disable" end
    return string
end
--[[ Splits a line at the designated delimiter ]]
function MTTSM_Settings_LineSplit(input,delim)
	MTTSM_Settings_LineSplitResult = {}
	--print(input)
	for i in string.gmatch(input,delim) do table.insert(MTTSM_Settings_LineSplitResult,i) end
	--print("MTTSM_Settings_LineSplitResult: "..table.concat(MTTSM_Settings_LineSplitResult,",",1,#MTTSM_Settings_LineSplitResult))
	return MTTSM_Settings_LineSplitResult
end
--[[ Page initialization ]]
local function MTTSM_Page_Init()
    if MTTSM_PageInitStatus == 0 then MTTSM_Refresh_PageDB(MTTSM_PageTitle) MTTSM_PageInitStatus = 1 end
end
--[[

IMGUI WINDOW ELEMENT

]]
function MTTSM_Win_Settings()
    --[[ Check page init status ]]
    MTTSM_Page_Init()
    --[[ Button ]]
    if MTTSM_SettingsValGet("Window_Page") == MTTSM_PageNumGet("Main Menu") then
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        if imgui.Button(MTTSM_PageTitle,(MTTSM_SettingsValGet("Window_W")-30),20) then 
            MTTSM_SettingsValSet("Window_Page",MTTSM_PageNumGet(MTTSM_PageTitle))
            MTTSM_Settings_CheckAutosave() 
        end
        MTTSM_ItemTooltip("Manage "..MTTSM_ScriptName.."' UI and general module settings")
    end
    --[[ Page ]]
    if MTTSM_SettingsValGet("Window_Page") == MTTSM_PageNumGet(MTTSM_PageTitle) then
        --[[ Set the page title ]]
        float_wnd_set_title(MTTSM_Window, MTTSM_ScriptName.." ("..MTTSM_PageTitle..")")
        --[[ "Main Menu" button ]]
        MTTSM_Win_Button_Back("Main Menu")
        --[[ Message display time ]]
        imgui.PushItemWidth(50)
        local changed,buffer = imgui.InputInt("  Notification Display Time (Seconds) ##10",MTTSM_SettingsValGet("NotificationDispTime"),0,0)
        if changed then MTTSM_SettingsValSet("NotificationDispTime",buffer) MTTSM_Settings_CheckAutosave() buffer = nil end
        MTTSM_ItemTooltip("Affects notifications at the bottom of the main window")
        imgui.PopItemWidth()
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        --[[ Hotkey options ]]
        if imgui.Button(MTTSM_ValToStr(MTTSM_SettingsValGet("WindowToggleByHotkey")).." Window Toggling By Hotkey ##20",(MTTSM_SettingsValGet("Window_W")-30),20) then 
            if MTTSM_SettingsValGet("WindowToggleByHotkey") == 0 then MTTSM_SettingsValSet("WindowToggleByHotkey",1)
            elseif MTTSM_SettingsValGet("WindowToggleByHotkey") == 1 then MTTSM_SettingsValSet("WindowToggleByHotkey",0) end 
            MTTSM_Settings_CheckAutosave()
        end
        MTTSM_ItemTooltip("Manages a custom hotkey for toggling the main window, avoiding a permanent key binding in X-Plane's keyboard configuration menu.\nWARNING: This key will be blocked for use by X-Plane or any other script/tool")
        if MTTSM_SettingsValGet("WindowToggleByHotkey") == 1 then 
            imgui.PushItemWidth(((MTTSM_SettingsValGet("Window_W") / 2)-30))
            local changed,buffer = imgui.InputInt("  Keyboard Key Code##21",MTTSM_SettingsValGet("WindowToggleHotkey"),0,0) 
            if changed then MTTSM_SettingsValSet("WindowToggleHotkey",buffer) MTTSM_Settings_CheckAutosave() buffer = nil end
            MTTSM_ItemTooltip("Find keyboard key codes with FlyWithLua's 'Show Keystroke Numbers' function (see FWL menu).\nAlternatively, you can assign a key to this script's 'Toggle Window' command in XP11's keyboard assignment menu. Make sure to disable this internal hotkey before doing so.")
            imgui.PopItemWidth() 
            imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        end
        --[[ Autosave options ]]
        if imgui.Button(MTTSM_ValToStr(MTTSM_SettingsValGet("AutoSave")).." Autosave##30",(MTTSM_SettingsValGet("Window_W")-30),20) then 
            if MTTSM_SettingsValGet("AutoSave") == 0 then MTTSM_SettingsValSet("AutoSave",1)
            elseif MTTSM_SettingsValGet("AutoSave") == 1 then MTTSM_SettingsValSet("AutoSave",0) end 
            MTTSM_SettingsFileWrite()
        end
        MTTSM_ItemTooltip("Toggles global autosaving (UI and all modules) for "..MTTSM_ScriptName)
    --			if MTTSM_SettingsValGet("AutoSave") then
    --				imgui.SameLine() imgui.TextUnformatted("(interval in seconds):") imgui.SameLine()
    --				local changed, newAutoSave_Time = imgui.InputText("##41", MTTSM_Preferences.AutoSave_Time, 4)
    --				if changed and newAutoSave_Time ~= "" and tonumber(newAutoSave_Time) then MTTSM_Preferences.AutoSave_Time = newAutoSave_Time MTTSM_SettingsFileWrite() end
    --			end
        --[[ Autoload options ]]
        if imgui.Button(MTTSM_ValToStr(MTTSM_SettingsValGet("AutoLoad")).." Autoload##40",(MTTSM_SettingsValGet("Window_W")-30),20) then 
            if MTTSM_SettingsValGet("AutoLoad") == 0 then MTTSM_SettingsValSet("AutoLoad",1)
            elseif MTTSM_SettingsValGet("AutoLoad") == 1 then MTTSM_SettingsValSet("AutoLoad",0) end 
            MTTSM_SettingsFileWrite()
        end
        MTTSM_ItemTooltip("Toggles global autloading (UI and all modules) after script start for "..MTTSM_ScriptName)
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        -- [[ Window information ]]
        imgui.TextUnformatted("Current Window Size (W,H) / Pos. (X,Y): "..imgui.GetWindowWidth()..","..imgui.GetWindowHeight().." / "..MTTSM_Window_Pos[1]..","..MTTSM_Window_Pos[2])
        imgui.TextUnformatted("Screen Width / Height:                  "..SCREEN_WIDTH.." x "..SCREEN_HIGHT.." Px")
        MTTSM_GetWindowInfo()
        imgui.TextUnformatted("Window size is saved automatically!")
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        -- [[ Settings file control buttons ]]
        if imgui.Button("Save UI Settings ##50",(MTTSM_SettingsValGet("Window_W")-30),20) then MTTSM_SettingsFileWrite() end
        MTTSM_ItemTooltip("Saves stored UI settings to "..MTTSM_SettingsFile)
        if imgui.Button("Load UI Settings ##60",(MTTSM_SettingsValGet("Window_W")-30),20) then MTTSM_SettingsFileRead() end
        MTTSM_ItemTooltip("Loads stored UI settings from "..MTTSM_SettingsFile)
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        if imgui.Button("Delete UI Settings",(MTTSM_SettingsValGet("Window_W")-30),20) then MTTSM_SettingsFileDelete() MTTSM_Initialized = false end
        MTTSM_ItemTooltip("Deletes stored UI settings")
        -- End of settings page 		
    end
end
