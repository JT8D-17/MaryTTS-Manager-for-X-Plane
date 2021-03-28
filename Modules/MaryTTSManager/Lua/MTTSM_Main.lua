--[[

Lua Module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

VARIABLES (local to this module)

]]
local MTTSM_PageTitle = "Main"      -- Page title
local MTTSM_PageInitStatus = 0            -- Page initialization variable
local MTTSM_Module_SaveFile = MODULES_DIRECTORY.."MaryTTSManager/MaryTTS_Test.cfg" -- Path to config file
local MTTSM_BaseFolder = MODULES_DIRECTORY.."MaryTTSManager/Resources/"
local MTTSM_InterfFolder = MODULES_DIRECTORY.."MaryTTSManager/Interfaces"
local MTTSM_InterfaceContainer = {  -- Container for interfaces
{"None/Testing"},       -- Default interface for local output
{"Create New Interface"}, -- Creates new interface
}
local MTTSM_InterfaceData = {
{"PluginName"},           -- SAVE FILE IDENTIFIER; KEEP UNIQUE TO THIS ARRAY
{"Dataref","None"},
{"Input","None"},
{"Output",MTTSM_BaseFolder.."transmission.wav"},
{"Voicemap"},
}
local MTTSM_JREFolder = MTTSM_BaseFolder.."JRE/Linux/jdk-11.0.7+10-jre/bin/"
local MTTSM_MaryFolder = MTTSM_BaseFolder.."marytts-5.2/"
local MTTSM_ServerLog = MTTSM_MaryFolder.."log/server.log"
local MTTSM_Log = MTTSM_BaseFolder.."Log_MaryTTS.txt"
local MTTSM_Handle = "marytts.server.Mary"
local MTTSM_OutputWav = MTTSM_BaseFolder.."transmission.wav"
local MTTSM_Process = nil
local MTTSM_Status = "Stopped"
local MTTSM_InterfaceSelected = MTTSM_InterfaceContainer[1][1] --"Select an interface"
local MTTSM_InterfaceEditMode = 0
local MTTSM_VoiceList = { }
local MTTSM_VoiceSelected = " "
local MTTSM_FilterList = {"None","JetPilot"}
local MTTSM_TestString = " "
--[[

FUNCTIONS

]]
--[[
SERVER
]]
--[[ Checks the MaryTTS server's log file for startup and shutdown indicatons ]]
local function MTTSM_CheckServerLog(mode)
   local file = io.open(MTTSM_ServerLog,"r")
   if file then
        for line in file:lines() do
            if mode == "Starting" and string.match(line,"marytts.server Waiting for client to connect on port") then MTTSM_Status = "Running" MTTSM_Notification("MaryTTS server: Started","Success") MTTSM_Log_Write("MaryTTS server: Started (PID: "..MTTSM_Process..")") end
            if mode == "Stopping" and string.match(line,"marytts.main Shutdown complete.") then print("xxx") MTTSM_Status = "Stopped" MTTSM_Notification("MaryTTS server: Stopped","Success") MTTSM_Log_Write("MaryTTS server: Stopped") end
        end
   end
end
--[[ Starts the MaryTTS server ]]
local function MTTSM_Server_Start()
    os.remove(MTTSM_ServerLog) MTTSM_Notification("FILE DELETE: "..MTTSM_ServerLog,"Warning","log") MTTSM_Log_Write("MaryTTS: Deleted old server log file")
    if MTTSM_Status == "Stopped" then
        os.execute('nohup \"'..MTTSM_JREFolder..'/java\" -showversion -Xms40m -Xmx1g -cp \"'..MTTSM_MaryFolder..'/lib/*\" -Dmary.base=\"'..MTTSM_MaryFolder..'\" $* '..MTTSM_Handle..' >> \"'..MTTSM_Log..'\" &')
        MTTSM_Notification("MaryTTS server: Starting","Advisory") MTTSM_Log_Write("MaryTTS server: Starting")
        MTTSM_Status = "Starting"
    end
end
--[[ Stops the MaryTTS server ]]
local function MTTSM_Server_Stop()
    if MTTSM_Status == "Running" then
        os.execute('kill '..MTTSM_Process)
        MTTSM_Notification("MaryTTS server: Stopping","Advisory") MTTSM_Log_Write("MaryTTS server: Stopping")
        MTTSM_Status = "Stopping"
    end
end
--[[ Speaks an input string with the input voice ]]
local function MTTSM_ProcessString(voice,inputstring)
    
    os.remove(MTTSM_OutputWav)
    local temp = inputstring:gsub(" ","%%20")
    --print(inputstring.."\n"..temp)
    os.execute('curl -o '..MTTSM_OutputWav..' "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&AUDIO=WAVE_FILE&VOICE='..voice..'&INPUT_TEXT="'..temp)
    --os.execute('curl -o '..MTTSM_OutputWav..' "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&effect_Volume_parameters=amount%3D2.0%3B&effect_Volume_selected=on&AUDIO=WAVE_FILE&VOICE='..voice..'&INPUT_TEXT="'..temp)
    --os.execute('curl -o '..MTTSM_OutputWav..' "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&&effect_Volume_parameters=amount%3D2.0%3B&effect_Volume_selected=on&effect_JetPilot_selected=on&AUDIO=WAVE_FILE&VOICE='..voice..'&INPUT_TEXT="'..temp)
end
--[[ Plays the output Wav file ]]
local function MTTSM_PlayWav()
    local f=io.open(MTTSM_OutputWav,"r")
    if f ~= nil then
        io.close(f)
        local OutputWav = load_WAV_file(MTTSM_OutputWav)
        play_sound(OutputWav)
        os.remove(MTTSM_OutputWav)
    end
end
--[[ Look for MaryTTS' process ]]
local function MTTSM_CheckProc()
    local handle = io.popen('pgrep -f '..MTTSM_Handle)
    MTTSM_Process = tonumber(handle:read("*a"))
    --print(tostring(MTTSM_Process))
end
--[[ MaryTTS watchdog - runs every second ]]
function MTTSM_Watchdog()
    -- Process checking function
    MTTSM_CheckProc()
    -- Status checking
    if MTTSM_Status == "Starting" then MTTSM_CheckServerLog("Starting") end
    if MTTSM_Status == "Stopping" then MTTSM_CheckServerLog("Stopping") end
    if MTTSM_Process ~= nil and MTTSM_Status == "Stopped" then MTTSM_CheckServerLog("Starting") MTTSM_Log_Write("MaryTTS server: Already running (PID: "..MTTSM_Process..")") end
    MTTSM_PlayWav()
end
do_often("MTTSM_Watchdog()")
--[[
INTERFACES
]]
--[[ Get a list of files and save it to a table ]]
local function MTTSM_GetFileList(inputdir,outputtable,filter)
    local resfile = nil
    if SYSTEM == "IBM" then resfile = io.popen('dir "'..inputdir..'" /b')
    elseif SYSTEM == "LIN" then resfile = io.popen('ls -AU1N "'..inputdir..'"')
    elseif SYSTEM == "APL" then 
    else return end
    if resfile ~= nil then
        if filter == "voice" then for i= 1, #outputtable do outputtable[i] = nil end end -- Reset output table
        if filter == "*.cfg" then for i= 3, #outputtable do outputtable[i] = nil end end -- Reset output table
        for filename in resfile:lines() do
            -- Voices
            if filter == "voice" and string.find(filename,"voice-") then 
                local voicefile = io.open(inputdir.."/"..filename,"r")
                for line in voicefile:lines() do
                    if string.match(line,"%sname=") then
                        outputtable[#outputtable+1] = string.match(line,"%sname=\"(.+)\"%stype")
                    end
                end
                voicefile:close()
                if #outputtable > 1 then MTTSM_VoiceSelected = outputtable[1] MTTSM_TestString = "Hello, I am "..MTTSM_VoiceSelected..", a TTS voice." end
            end
            -- Interface files
            if filter == "*.cfg" then 
                if string.gmatch(filename,filter) then
                    outputtable[#outputtable+1] = { }
                    outputtable[#outputtable][1] = filename:match "[^.]+" 
                end
            end
        end
        resfile:close()
        --if filter == "voice" then print(table.concat(outputtable,", ")) end -- Debug output
        --if filter == "*.cfg" then for j=1,#outputtable do print(outputtable[j][1]) end end -- Debug output
    end
    return outputtable
end
--[[ Load an interface ]]
local function MTTSM_InterfaceLoad(inputfolder,container,datatable)
    MTTSM_GetFileList(inputfolder,container,"*.cfg")                              -- Obtains the list of interfaces
    for i=1,#container do
        -- Build subtables in container table
        container[i][2] = { }
        container[i][2][1] = { }
        if i ~= 2 then container[i][2][1][1] = container[i][1] else container[i][2][1][1] = "New Interface" end --MTTSM_InterfaceData[1][1] -- "PluginName"
        container[i][2][2] = { }
        container[i][2][2][1] = MTTSM_InterfaceData[2][1] -- "Dataref"
        container[i][2][3] = { }
        container[i][2][3][1] = MTTSM_InterfaceData[3][1] -- "Input"
        container[i][2][4] = { }
        container[i][2][4][1] = MTTSM_InterfaceData[4][1] -- "Output"
        container[i][2][5] = { }
        container[i][2][5][1] = MTTSM_InterfaceData[5][1] -- "Voicemap"
        -- Fill subtable for the default interface
        container[i][2][2][2] = MTTSM_InterfaceData[2][2] -- "Dataref"
        container[i][2][3][2] = MTTSM_InterfaceData[3][2] -- "Input"
        container[i][2][4][2] = MTTSM_InterfaceData[4][2] -- "Output"
        container[i][2][5][2] = MTTSM_InterfaceData[5][2] -- "Voicemap"
        -- Read interface files
        if i >= 3 then MTTSM_FileRead(inputfolder.."/"..container[i][1]..".cfg",container[i][2]) end -- Read data from file into interface data table
    end
    --for m=1,#container do print(container[m][2][5][1]) print(#container[m][2][5]) end
end
--[[ Select an interface ]]
local function MTTSM_InterfaceSelector(inputtable)
    imgui.TextUnformatted("Selected Interface  ") imgui.SameLine()
    imgui.PushItemWidth(MTTSM_SettingsValGet("Window_W")-278)
    if imgui.BeginCombo("##Combo1",MTTSM_InterfaceSelected) then
        -- Loop over all choices
        for i = 1, #inputtable do
            if imgui.Selectable(inputtable[i][1], choice == i) then
                MTTSM_InterfaceSelected = inputtable[i][1]
                --print(MTTSM_InterfaceSelected)
                choice = i
            end
        end
    imgui.EndCombo()
    end
    imgui.PopItemWidth()
    imgui.SameLine()
    if imgui.Button("Rescan",90,20) then MTTSM_InterfaceLoad(MTTSM_InterfFolder,MTTSM_InterfaceContainer,MTTSM_InterfaceData) end
end
--[[ Add a voice mapping ]]
local function MTTSM_AddVoiceMapping(inputtable)
    --local index = MTTSM_SubTableIndex(inputtable,"Voicemap")
    --print(inputtable[index][1])
    local temptable = {"None","None"}
    MTTSM_SubTableAdd(inputtable,"Voicemap",temptable)
end
--[[ Display interface data ]]
local function MTTSM_InterfaceStatus(inputtable)
    --MTTSM_InterfaceSelected = "SimpleATC"
    local tabindex = MTTSM_SubTableIndex(inputtable,MTTSM_InterfaceSelected)
    local editstring = "    "
    if MTTSM_InterfaceEditMode == 1 then editstring = "New " else editstring = "    " end
    imgui.PushItemWidth(MTTSM_SettingsValGet("Window_W")-180)
    if MTTSM_InterfaceSelected == MTTSM_InterfaceContainer[2][1] then
        imgui.TextUnformatted(editstring.."Interface Name  ") imgui.SameLine()
        local changed,buffer = imgui.InputText("##InterfaceName "..MTTSM_InterfaceSelected,inputtable[tabindex][2][1][1], 256)
        if changed and buffer ~= "" and tostring(buffer) then inputtable[tabindex][2][1][1] = tostring(buffer) buffer = nil end
        MTTSM_ItemTooltip("The name of the interface and file name of its config file.")
    end
    if MTTSM_InterfaceSelected ~= MTTSM_InterfaceContainer[1][1] then
        imgui.TextUnformatted(editstring.."Plugin Dataref  ") imgui.SameLine()
        local changed,buffer = imgui.InputText("##Dataref"..MTTSM_InterfaceSelected,MTTSM_SubTableValGet(inputtable[tabindex][2],"Dataref",0,2), 256)
        if MTTSM_InterfaceEditMode == 1 then if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Dataref",0,2,tostring(buffer)) buffer = nil end end
        MTTSM_ItemTooltip("The dataref that is used to check whether another plugin is active or not. Currently set to:\n"..MTTSM_SubTableValGet(inputtable[tabindex][2],"Dataref",0,2))
    end
    imgui.TextUnformatted(editstring.."Input Text File ") imgui.SameLine()
    local changed,buffer = imgui.InputText("##Input"..MTTSM_InterfaceSelected,MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,2), 1024)
    if MTTSM_InterfaceEditMode == 1 then if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Input",0,2,tostring(buffer)) buffer = nil end end
    MTTSM_ItemTooltip("The text file the plugin writes its MaryTTS information into. Currently set to:\n"..MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,2))
    imgui.TextUnformatted(editstring.."Output WAV File ") imgui.SameLine()
    local changed,buffer = imgui.InputText("##Output"..MTTSM_InterfaceSelected,MTTSM_SubTableValGet(inputtable[tabindex][2],"Output",0,2), 1024)
    if MTTSM_InterfaceEditMode == 1 then if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Output",0,2,tostring(buffer)) buffer = nil end end
    MTTSM_ItemTooltip("The WAV file that MaryTTS is supposed to write its output to. Currently set to:\n"..MTTSM_SubTableValGet(inputtable[tabindex][2],"Output",0,2))
    imgui.PopItemWidth()
    if MTTSM_InterfaceSelected ~= MTTSM_InterfaceContainer[1][1] then
        if MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") > 1 then
            for j=2,MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") do
                imgui.PushItemWidth(MTTSM_SettingsValGet("Window_W")-370)
                imgui.TextUnformatted(editstring.."Voice Mapping "..string.format("%02d",(j-1))) imgui.SameLine()
                local changed,buffer = imgui.InputText("##Mapping"..MTTSM_InterfaceSelected..(j-1),MTTSM_SubTableValGet(inputtable[tabindex][2],"Voicemap",j,1), 256)
                --if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Voicemap",j,1,tostring(buffer)) buffer = nil end
                MTTSM_ItemTooltip("This is the keyword from the plugin's output text file that will be associated to the voice on the right. If the keyword does not match the one in the plugin output, a random voice will be selected.")
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.PushItemWidth(182)
                if imgui.BeginCombo("##Combo"..MTTSM_InterfaceSelected..(j-1), MTTSM_SubTableValGet(inputtable[tabindex][2],"Voicemap",j,2)) then
                    for k = 1, #MTTSM_VoiceList do
                        if imgui.Selectable(MTTSM_VoiceList[k], choice == k) then
                            if MTTSM_InterfaceEditMode == 1 then MTTSM_SubTableValSet(inputtable[tabindex][2],"Voicemap",j,2,MTTSM_VoiceList[k]) end
                            choice = j
                        end
                    end
                imgui.EndCombo()
                end
                MTTSM_ItemTooltip("The voice associated with the keyword to the left. If the voice is not installed, an installed voice will be randomly selected.")
                imgui.PopItemWidth()
            end
        end
        if MTTSM_InterfaceEditMode == 1 then
            imgui.TextUnformatted("    Voice Mapping   ") imgui.SameLine()
            if MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") > 1 then
                if imgui.Button("Remove",100,20) then MTTSM_ItemRemove(inputtable[tabindex][2],"Voicemap",MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap")) end
                MTTSM_ItemTooltip("Will remove voice mapping "..string.format("%02d",MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap")-1)..".")
            else
                imgui.Dummy(100,20)
            end
            imgui.SameLine() imgui.Dummy((MTTSM_SettingsValGet("Window_W")-395),20) imgui.SameLine()
            if imgui.Button("Add",100,20) then MTTSM_AddVoiceMapping(inputtable[tabindex][2]) end
            MTTSM_ItemTooltip("Add a new voice mapping (number "..string.format("%02d",MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap"))..").")
            imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
            imgui.Dummy(19,20) imgui.SameLine()
            if imgui.Button("Save Interface Configuration File",(MTTSM_SettingsValGet("Window_W")-59),20) then MTTSM_FileWrite(inputtable[tabindex][2],MTTSM_InterfFolder.."/"..inputtable[tabindex][2][1][1]..".cfg") end
            imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
        else
            imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),20)
        end
    else
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),20)
    end
    local buttonstring = "Disable"
    if MTTSM_InterfaceEditMode == 1 then buttonstring = "Disable" else buttonstring = "Enable" end
    imgui.Dummy(19,20) imgui.SameLine()
    if imgui.Button(buttonstring.." Edit Mode",(MTTSM_SettingsValGet("Window_W")-59),20) then if MTTSM_InterfaceEditMode == 0 then MTTSM_InterfaceEditMode = 1 else MTTSM_InterfaceEditMode = 0 end end
    imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),20)
end
--[[ Testing area ]]
local function MTTSM_Testing(inputtable)
    -- Only display this if a MaryTTS server is running
    if MTTSM_Process ~= nil and MTTSM_Status == "Running" and #inputtable >= 1 then
        imgui.PushItemWidth(MTTSM_SettingsValGet("Window_W")-180)
        imgui.TextUnformatted("    String To Speak ") imgui.SameLine()
        local changed,buffer = imgui.InputText("##SpeakString",MTTSM_TestString, 512)
        if changed and buffer ~= "" and tostring(buffer) then MTTSM_TestString = buffer buffer = nil end
        imgui.TextUnformatted("    Voice To Use    ") imgui.SameLine()
        if imgui.BeginCombo("##Combo2", MTTSM_VoiceSelected) then
            -- Loop over all choices
            for i = 1, #inputtable do
                if imgui.Selectable(inputtable[i], choice == i) then
                    MTTSM_VoiceSelected = inputtable[i]
                    choice = i
                    MTTSM_TestString = "Hello, I am "..MTTSM_VoiceSelected..", a TTS voice."
                end
            end
            imgui.EndCombo()
        end
        imgui.PopItemWidth()
        --imgui.TextUnformatted("Volume/Filter:        ") --imgui.SameLine()
        --imgui.SameLine() imgui.Dummy((MTTSM_SettingsValGet("Window_W")-395),20) imgui.SameLine()
        --imgui.Dummy(MTTSM_SettingsValGet("Window_W")-180,5)
        imgui.Dummy(19,20) imgui.SameLine()
        if imgui.Button("Speak",MTTSM_SettingsValGet("Window_W")-59,20) then MTTSM_ProcessString(MTTSM_VoiceSelected,MTTSM_TestString) end
    else
        imgui.Dummy(19,20) imgui.SameLine()
        imgui.TextUnformatted("MaryTTS server is not running; testing area disabled!")
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),40)
    end
    imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),20)
end
--[[

DATAREFS

]]
--[[ Dataref table: Name, dataref, array length, current value(s) ]]
local MTTSM_Module_DRefs = {
--{"Sim Date","sim/time/local_date_days",1,{}},   
}
--[[ 

INITIALIZATION

]]
function MTTSM_ModuleInit_MTTSM_Main()
    if MTTSM_SettingsValGet("AutoLoad") == 1 then 
        MTTSM_Log_Write(MTTSM_PageTitle..": Autoloading values from "..MTTSM_Module_SaveFile) 
        --MTTSM_FileRead(MTTSM_Module_SaveFile,MTTSM_InterfaceData)
    end
end
--[[ 

IMGUI WINDOW ELEMENT

]]
--[[ Window page initialization ]]
local function MTTSM_Page_Init()
    if MTTSM_PageInitStatus == 0 then MTTSM_Refresh_PageDB(MTTSM_PageTitle) MTTSM_InterfaceLoad(MTTSM_InterfFolder,MTTSM_InterfaceContainer,MTTSM_InterfaceData) MTTSM_GetFileList(MTTSM_MaryFolder.."/installed",MTTSM_VoiceList,"voice") MTTSM_PageInitStatus = 1 end
end
--[[ Window content ]]
function MTTSM_Win_MTTSM_Main()
    --[[ Check page init status ]]
    MTTSM_Page_Init()
    --[[ Button ]]
    if MTTSM_SettingsValGet("Window_Page") == MTTSM_PageNumGet("Main Menu") then
        --imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        if imgui.Button(MTTSM_PageTitle,(MTTSM_SettingsValGet("Window_W")-30),20) then 
            MTTSM_SettingsValSet("Window_Page",MTTSM_PageNumGet(MTTSM_PageTitle))
            float_wnd_set_title(MTTSM_Window, MTTSM_ScriptName.." ("..MTTSM_PageTitle..")")
            MTTSM_Settings_CheckAutosave() 
        end
        MTTSM_ItemTooltip("Test environment for MaryTTS")
    end
    --[[ Page ]]
    if MTTSM_SettingsValGet("Window_Page") == MTTSM_PageNumGet(MTTSM_PageTitle) then
        --[[ Set the page title ]]
        float_wnd_set_title(MTTSM_Window, MTTSM_ScriptName.." ("..MTTSM_PageTitle..")")
        --[[ "Main Menu" button ]]
        MTTSM_Win_Button_Back("Main Menu")
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
        --[[ File content ]]
        -- Interface selector
        MTTSM_InterfaceSelector(MTTSM_InterfaceContainer)
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
        MTTSM_InterfaceStatus(MTTSM_InterfaceContainer)
        -- Testing area
        if MTTSM_InterfaceSelected == MTTSM_InterfaceContainer[1][1] then MTTSM_Testing(MTTSM_VoiceList) end
        --[[ if imgui.Button("Check MaryTTS Server status",(MTTSM_SettingsValGet("Window_W")-30),20) then
            MTTSM_CheckProc()
        end ]]
        -- Server status display
        imgui.Dummy(19,20) imgui.SameLine()
        imgui.TextUnformatted("MaryTTS server status: "..MTTSM_Status)
        if MTTSM_Process ~= nil then imgui.SameLine() imgui.TextUnformatted("(Process ID: "..MTTSM_Process..")") end
        --imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
        -- Server control button
        imgui.Dummy(19,20) imgui.SameLine()
        if MTTSM_Process == nil and imgui.Button("Start MaryTTS Server",(MTTSM_SettingsValGet("Window_W")-59),20) then
            MTTSM_Server_Start()
        end
        if MTTSM_Process ~= nil and imgui.Button("Stop MaryTTS Server",(MTTSM_SettingsValGet("Window_W")-59),20) then
            MTTSM_Server_Stop()
        end
    --[[ End page ]]    
    end
end
