--[[

Lua Module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

VARIABLES (local to this module)

]]
local MTTSM_PageTitle = "Server and Interface"      -- Page title
local MTTSM_PageInitStatus = 0            -- Page initialization variable
local MTTSM_Module_SaveFile = MODULES_DIRECTORY.."MaryTTSManager/MaryTTS_Test.cfg" -- Path to config file
local MTTSM_BaseFolder = MODULES_DIRECTORY.."MaryTTSManager/Resources/"
local MTTSM_InterfFolder = MODULES_DIRECTORY.."MaryTTSManager/Interfaces"
local MTTSM_InputBaseFolder = {
    {"MaryTTSManager Directory",MODULES_DIRECTORY.."MaryTTSManager/"},
    {"X-Plane Plugins Directory",SYSTEM_DIRECTORY.."Resources"..DIRECTORY_SEPARATOR.."plugins/"},
    {"X-Plane Base Directory",SYSTEM_DIRECTORY},
    {"Current Aircraft Directory",AIRCRAFT_PATH},
    {"FWL Scripts Directory",SCRIPT_DIRECTORY},
    }
local MTTSM_InterfaceContainer = {  -- Container for interfaces
{"None/Testing"},       -- Default interface for local output
{"Create New Interface"}, -- Creates new interface
}
local MTTSM_InterfaceData = {
{"PluginName"},           -- SAVE FILE IDENTIFIER; KEEP UNIQUE TO THIS ARRAY
{"Dataref","None"},
{"Input",MTTSM_InputBaseFolder[1][1],"Input_MaryTTS.txt","::"},
{"Output",MTTSM_InputBaseFolder[1][1],"transmission.wav","FlyWithLua"},
{"Voicemap"},
}
local MTTSM_PlaybackAgent = {"FlyWithLua","Plugin"}
local MTTSM_JREFolder
if SYSTEM == "IBM" then MTTSM_JREFolder = MTTSM_BaseFolder.."JRE/Windows/jdk-11.0.7+10-jre/bin/"
elseif SYSTEM == "LIN" then MTTSM_JREFolder = MTTSM_BaseFolder.."JRE/Linux/jdk-11.0.7+10-jre/bin/"
elseif SYSTEM == "APL" then 
else return end
local MTTSM_MaryFolder = MTTSM_BaseFolder.."marytts-5.2/"
local MTTSM_ServerLog = MTTSM_MaryFolder.."log/server.log"
local MTTSM_Log = MTTSM_BaseFolder.."Log_MaryTTS.txt"
local MTTSM_Handle = "marytts.server.Mary"
local MTTSM_ProcHandle -- Initial MaryTTS server process handle
if SYSTEM == "IBM" then 
	MTTSM_ProcHandle = io.popen('start /b "TempWin" tasklist /FI "IMAGENAME eq java*" /FO CSV /NH')
local temp = string.match(MTTSM_ProcHandle:read("*a"),"exe\",\"(%d+)\",\"")
elseif SYSTEM == "LIN" then MTTSM_ProcHandle = io.popen('pgrep -f '..MTTSM_Handle)
elseif SYSTEM == "APL" then 
else return end
local MTTSM_Process = nil
local MTTSM_Status = "Stopped"
local MTTSM_InterfaceSelected = MTTSM_InterfaceContainer[1][1] --"Select an interface"
local MTTSM_InterfaceEditMode = 0
local MTTSM_VoiceList = { }
local MTTSM_VoiceSelected = " "
local MTTSM_PrevActor = {"None","None"}  -- The actor of the previous voice communication
local MTTSM_FilterList = {"None","JetPilot"}
local MTTSM_TestString = " "
local MTTSM_ActiveInterfaces = { }
local MTTSM_ServerProcessQueue = { }
local MTTSM_PlaybackTimer_Ref = {os.time(),0}
-- Prime random number generator
math.randomseed(os.time())
math.random(); math.random(); math.random()
--[[

FUNCTIONS

]]
--[[
DYNAMIC PATHS
]]
local function MTTSM_PathConstructor(interface,mode,size)
    local inputtable = MTTSM_InterfaceContainer
    local tabindex = MTTSM_SubTableIndex(inputtable,interface)
    if mode == "Input" or mode == "Output" then
        if size == "Full" then
            return MTTSM_SubTableValGet(MTTSM_InputBaseFolder,MTTSM_SubTableValGet(inputtable[tabindex][2],tostring(mode),0,2),0,2)..MTTSM_SubTableValGet(inputtable[tabindex][2],tostring(mode),0,3)
        end
        if size == "Base" then
            return MTTSM_SubTableValGet(MTTSM_InputBaseFolder,MTTSM_SubTableValGet(inputtable[tabindex][2],tostring(mode),0,2),0,2)
        end
    end
end
--[[
SERVER MANAGEMENT
]]
--[[ Look for MaryTTS' process ]]
local function MTTSM_CheckProc()
    if SYSTEM == "IBM" then 
		MTTSM_ProcHandle = io.popen('start /b "TempWin" tasklist /FI "IMAGENAME eq java*" /FO CSV /NH')
		MTTSM_Process = tonumber(string.match(MTTSM_ProcHandle:read("*a"),"exe\",\"(%d+)\",\""))
    elseif SYSTEM == "LIN" then 
		MTTSM_ProcHandle = io.popen('pgrep -f '..MTTSM_Handle)
		MTTSM_Process = tonumber(MTTSM_ProcHandle:read("*a"))
    elseif SYSTEM == "APL" then 
    else return end
    --print(tostring(MTTSM_Process))
end
--[[ Checks the MaryTTS server's log file for startup and shutdown indicatons ]]
local function MTTSM_CheckServerLog(mode)
   local file = io.open(MTTSM_ServerLog,"r")
   if file then
        for line in file:lines() do
            if mode == "Starting" and string.match(line,"marytts.server Waiting for client to connect on port") then
                MTTSM_CheckProc()
                if MTTSM_Process ~= nil then MTTSM_Status = "Running" MTTSM_Notification("MaryTTS Server: Started","Success") MTTSM_Log_Write("MaryTTS Server: Started (PID: "..MTTSM_Process..")") end
            end
            if mode == "Stopping" and string.match(line,"marytts.main Shutdown complete.") then
                MTTSM_CheckProc()
				if MTTSM_Process == nil then MTTSM_Status = "Stopped" MTTSM_Notification("MaryTTS Server: Stopped","Success") MTTSM_Log_Write("MaryTTS Server: Stopped") break end
			end
        end
   end
end
--[[ Starts the MaryTTS server ]]
local function MTTSM_Server_Start()
    os.remove(MTTSM_ServerLog) MTTSM_Notification("FILE DELETE: "..MTTSM_ServerLog,"Warning","log") MTTSM_Log_Write("MaryTTS Server: Deleted old server log file")
    if MTTSM_Status == "Stopped" then
        if SYSTEM == "IBM" then os.execute('start /b \"MaryTTSConsoleWindow\" \"'..MTTSM_JREFolder..'\\java.exe\" -showversion -Xms40m -Xmx1g -cp \"'..MTTSM_MaryFolder..'\\lib\\*\" -Dmary.base=\"'..MTTSM_MaryFolder..'\" $* '..MTTSM_Handle..' >> \"'..MTTSM_Log..'\"')
        elseif SYSTEM == "LIN" then os.execute('nohup \"'..MTTSM_JREFolder..'/java\" -showversion -Xms40m -Xmx1g -cp \"'..MTTSM_MaryFolder..'/lib/*\" -Dmary.base=\"'..MTTSM_MaryFolder..'\" $* '..MTTSM_Handle..' >> \"'..MTTSM_Log..'\" &')
		elseif SYSTEM == "APL" then 
		else return end        
        MTTSM_Notification("MaryTTS Server: Starting","Advisory") MTTSM_Log_Write("MaryTTS Server: Starting")
        MTTSM_Status = "Starting"
    end
end
--[[ Stops the MaryTTS server ]]
local function MTTSM_Server_Stop()
    if MTTSM_Status == "Running" then
		if SYSTEM == "IBM" then os.execute('Taskkill /PID '..MTTSM_Process..' /F')
        elseif SYSTEM == "LIN" then os.execute('kill '..MTTSM_Process)
 		elseif SYSTEM == "APL" then 
		else return end        
        MTTSM_Notification("MaryTTS Server: Stopping","Advisory") MTTSM_Log_Write("MaryTTS Server: Stopping")
        MTTSM_Status = "Stopping"
    end
end
--[[
PLAYBACK
]]
--[[ Determines the filesize ]]
local function MTTS_GetFileSize(file)
        local current = file:seek()      -- get current position
        local size = file:seek("end")    -- get file size
        file:seek("set", current)        -- restore position
        return size
end
--[[ Writes to the selected output file ]]
local function MTTSM_OutputToFile(interface,voice,string)
    --print(voice.." says: "..string)
    local inputtable = MTTSM_InterfaceContainer
    local tabindex = MTTSM_SubTableIndex(inputtable,interface)
    local textfile = io.open(MTTSM_PathConstructor(interface,"Input","Full"),"a")
    if textfile then
        textfile:write(voice,MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,4),string,"\n")
        --print("MTTSM: Writing \""..voice..MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,4)..string.."\\n\" to "..MTTSM_PathConstructor(interface,"Input","Full"))
        textfile:close()
    end
end
-- [[ Reads the selected input file ]]
local function MTTSM_InputFromFile(interface)
    local inputtable = MTTSM_InterfaceContainer
    local tabindex = MTTSM_SubTableIndex(inputtable,interface)
    local textfile = io.open(MTTSM_PathConstructor(interface,"Input","Full"),"r")
    local oldqueuesize = #MTTSM_ServerProcessQueue
    if textfile then
        for line in textfile:lines() do     -- Fill process queue
            local splitline = MTTSM_SplitString(line,"([^"..MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,4).."]+)")
            MTTSM_ServerProcessQueue[#MTTSM_ServerProcessQueue+1] = splitline
            MTTSM_ServerProcessQueue[#MTTSM_ServerProcessQueue][#MTTSM_ServerProcessQueue[#MTTSM_ServerProcessQueue]+1] = MTTSM_PathConstructor(interface,"Output","Full")
        end
        textfile:close()
        os.remove(MTTSM_PathConstructor(interface,"Input","Full"))
        --print("MTTSM: MaryTTS Input Queue Length Size: "..#MTTSM_ServerProcessQueue.." (+"..(#MTTSM_ServerProcessQueue-oldqueuesize)..")")
    end
    -- Sends the first item from the process queue to the MaryTTS server
    if #MTTSM_ServerProcessQueue > 0 then
        local f = io.open(MTTSM_ServerProcessQueue[1][3],"r") -- Check for presence of output WAV
        if f == nil then
            -- Assigns a a voice from the voice mapping or randomly
            if MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") > 1 then
                for j=2,MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") do
                    if MTTSM_ServerProcessQueue[1][1] == MTTSM_SubTableValGet(inputtable[tabindex][2],"Voicemap",j,1) then MTTSM_ServerProcessQueue[1][1] = MTTSM_SubTableValGet(inputtable[tabindex][2],"Voicemap",j,2) -- Voice mapping found
                    elseif j == MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") then -- Voice mapping not found
                        if MTTSM_ServerProcessQueue[1][1] ~= MTTSM_PrevActor[1] then -- Actor different to previous one
                            local newactorname = MTTSM_ServerProcessQueue[1][1]
                            MTTSM_ServerProcessQueue[1][1] = MTTSM_VoiceList[math.random(1,#MTTSM_VoiceList)]
                            for k=2,MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") do
                                if MTTSM_ServerProcessQueue[1][1] == MTTSM_SubTableValGet(inputtable[tabindex][2],"Voicemap",k,1) then 
                                    MTTSM_ServerProcessQueue[1][1] = MTTSM_VoiceList[math.random(1,#MTTSM_VoiceList)] 
                                    MTTSM_Log_Write("MTTSM: Voice already mapped. Retrying...")
                                end
                            end
                            MTTSM_Log_Write("Actor Change (Random Voice): "..MTTSM_PrevActor[1].." ("..MTTSM_PrevActor[2]..") -> "..newactorname.." ("..MTTSM_ServerProcessQueue[1][1]..")")
                            MTTSM_PrevActor[1] = newactorname                   -- Update old actor table: Name
                            MTTSM_PrevActor[2] = MTTSM_ServerProcessQueue[1][1] -- Update old actor table: Voice
                        else
                            MTTSM_ServerProcessQueue[1][1] = MTTSM_PrevActor[2]
                        end
                    end
                end
            end
            MTTSM_Log_Write("MTTSM: "..MTTSM_ServerProcessQueue[1][1].." says \""..MTTSM_ServerProcessQueue[1][2].."\" and outputs to "..MTTSM_ServerProcessQueue[1][3])
            --
            local temp = MTTSM_ServerProcessQueue[1][2]:gsub(" ","%%20")
            if SYSTEM == "IBM" then os.execute('start /b \"CurlWin\" curl -o '..MTTSM_ServerProcessQueue[1][3]..' "http://localhost:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&AUDIO=WAVE_FILE&VOICE='..MTTSM_ServerProcessQueue[1][1]..'&INPUT_TEXT="'..temp)
            elseif SYSTEM == "LIN" then os.execute('curl -o '..MTTSM_ServerProcessQueue[1][3]..' "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&AUDIO=WAVE_FILE&VOICE='..MTTSM_ServerProcessQueue[1][1]..'&INPUT_TEXT="'..temp)
			elseif SYSTEM == "APL" then 
			else return end                    
            --os.execute('curl -o '..MTTSM_ServerProcessQueue[1][3]..' "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&effect_Volume_parameters=amount%3D2.0%3B&effect_Volume_selected=on&AUDIO=WAVE_FILE&VOICE='..MTTSM_ServerProcessQueue[1][1]..'&INPUT_TEXT="'..temp)
            --os.execute('curl -o '..MTTSM_ServerProcessQueue[1][3]..' "http://127.0.0.1:59125/process?INPUT_TYPE=TEXT&OUTPUT_TYPE=AUDIO&LOCALE=en_US&&effect_Volume_parameters=amount%3D2.0%3B&effect_Volume_selected=on&effect_JetPilot_selected=on&AUDIO=WAVE_FILE&VOICE='..MTTSM_ServerProcessQueue[1][1]..'&INPUT_TEXT="'..temp)
            --
            table.remove(MTTSM_ServerProcessQueue,1)
            --print("MTTSM: MaryTTS Input Queue Length Size: "..#MTTSM_ServerProcessQueue)
        end
    end
    -- If playback is set to FWL, play WAV file there
    if MTTSM_SubTableValGet(inputtable[tabindex][2],"Output",0,4) == "FlyWithLua" then
        local out_wav = MTTSM_PathConstructor(interface,"Output","Full")
        local f = io.open(out_wav,"r") -- Check for presence of output WAV
        if f ~= nil then
            local fsize = MTTS_GetFileSize(f)
            --print("MTTSM: Filesize is "..fsize.." bytes; length is "..(fsize/32000).." seconds")e5rzwertzw
            io.close(f)
            -- Timer:
            if MTTSM_PlaybackTimer_Ref[2] == 1 then -- Unlock delay before first playback
                if os.time() > (MTTSM_PlaybackTimer_Ref[1] + math.ceil(fsize/32000)) then
                    print("MTTSM: Playing "..out_wav)
                    if OutputWav == nil then OutputWav = load_WAV_file(out_wav) else replace_WAV_file(OutputWav,out_wav) end
                    set_sound_gain(OutputWav,1.5)
                    play_sound(OutputWav)
                    os.remove(out_wav)
                    MTTSM_PlaybackTimer_Ref[1] = os.time()
                end
            else
                MTTSM_PlaybackTimer_Ref[2] = 1
            end
        end
    end
end
--[[
PROCESS
]]
--[[ MaryTTS watchdog - runs every second in MTTSM_Main_1sec() in MaryTTSManager.lua ]]
function MTTSM_Watchdog()
    --MTTSM_CheckProc() -- Continuous process check - disabled for performance reasons
    if MTTSM_Status == "Starting" then MTTSM_CheckServerLog("Starting") end -- Status check during MaryTTS server startup
    if MTTSM_Status == "Stopping" then MTTSM_CheckServerLog("Stopping") end -- Status check during MaryTTS server shutdown
    if MTTSM_Process ~= nil and MTTSM_Status ~= "Running" then MTTSM_CheckServerLog("Starting") if MTTSM_Process ~= nil then MTTSM_Log_Write("MaryTTS Server: Already running (PID: "..MTTSM_Process..")") end end
    -- Stuff to do when the server is up and running
    if MTTSM_Process ~= nil and MTTSM_Status == "Running" and MTTSM_InterfaceEditMode == 0 then
        for i=1,#MTTSM_ActiveInterfaces do -- Iterate through active interfaces
            for j=1,#MTTSM_InterfaceContainer do
                if MTTSM_InterfaceContainer[j][2][1][1] == MTTSM_ActiveInterfaces[i] then -- Match active interface to subtable index in container
                    MTTSM_InputFromFile(MTTSM_InterfaceContainer[j][2][1][1])
                end
            end
        end
    end
end
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
        local indexvar = nil
        container[i][2] = { } -- Create empty table in container table
        for j=1,#datatable do container[i][2][j] = { } end -- Fill container subtable with empty tables corresponding to the size of the input datatable
        -- Build subtables in container table
        if i ~= 2 then container[i][2][1][1] = container[i][1] else container[i][2][1][1] = "New Interface" end -- First subtable in container subtable is reserved for the interface name
        indexvar = MTTSM_SubTableIndex(datatable,"Dataref")
        for k =1,#MTTSM_InterfaceData[indexvar] do container[i][2][indexvar][k] = MTTSM_InterfaceData[indexvar][k] end -- Write default values for dataref subtable to subtable in container
        indexvar = MTTSM_SubTableIndex(datatable,"Input")
        for k =1,#MTTSM_InterfaceData[indexvar] do container[i][2][indexvar][k] = MTTSM_InterfaceData[indexvar][k] end -- Write default values for input subtable to subtable in container
        indexvar = MTTSM_SubTableIndex(datatable,"Output")
        for k =1,#MTTSM_InterfaceData[indexvar] do container[i][2][indexvar][k] = MTTSM_InterfaceData[indexvar][k] end -- Write default values for output subtable to subtable in container
        indexvar = MTTSM_SubTableIndex(datatable,"Voicemap")
        for k =1,#MTTSM_InterfaceData[indexvar] do container[i][2][indexvar][k] = MTTSM_InterfaceData[indexvar][k] end -- Write default values for voicemap subtable to subtable in container
        -- Read interface files
        if i >= 3 then MTTSM_FileRead(inputfolder.."/"..container[i][1]..".cfg",container[i][2]) end -- Read data from file into interface data table
    end
    --for m=1,#container do print(container[m][2][5][1]) print(#container[m][2][5]) end
end
--[[ Select an interface ]]
local function MTTSM_InterfaceSelector(inputtable)
    imgui.TextUnformatted("Selected Interface  ") imgui.SameLine()
    imgui.PushItemWidth(MTTSM_SettingsValGet("Window_W")-278)
    if imgui.BeginCombo("##ComboInterfaceSelect",MTTSM_InterfaceSelected) then
        -- Loop over all choices
        for i = 1, #inputtable do
            if imgui.Selectable(inputtable[i][1], choice == i) then
                MTTSM_InterfaceSelected = inputtable[i][1]
                --print(MTTSM_InterfaceSelected)
                if MTTSM_InterfaceSelected == "Create New Interface" then if MTTSM_InterfaceEditMode == 0 then MTTSM_InterfaceEditMode = 1 end
                else if MTTSM_InterfaceEditMode == 1 then MTTSM_InterfaceEditMode = 0 end end
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
--[[ Find active interfaces ]]
local function MTTSM_FindActiveInterfaces(container)
    local inactiveifs = { }
    MTTSM_ActiveInterfaces[1] = container[1][2][1][1]
    for i=3,#container do
        if XPLMFindDataRef(MTTSM_SubTableValGet(container[i][2],"Dataref",0,2)) then 
            MTTSM_ActiveInterfaces[#MTTSM_ActiveInterfaces+1] = container[i][2][1][1]
        else
            inactiveifs[#inactiveifs+1] = container[i][2][1][1]
        end
    end
    MTTSM_Log_Write("MaryTTS Interfaces (Active): "..table.concat(MTTSM_ActiveInterfaces,", "))
    MTTSM_Log_Write("MaryTTS Interfaces (Inctive): "..table.concat(inactiveifs,", "))
end
--[[

UI ELEMENTS

]]
--[[ Interface status/editor ]]
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
    imgui.TextUnformatted(editstring.."Input Base Path ") imgui.SameLine()
    if imgui.BeginCombo("##ComboInputFile",MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,2)) then
        for i = 1, #MTTSM_InputBaseFolder do
            if imgui.Selectable(MTTSM_InputBaseFolder[i][1], choice == i) then
                MTTSM_SubTableValSet(inputtable[tabindex][2],"Input",0,2,MTTSM_InputBaseFolder[i][1])
                --print(MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,2).." -> "..MTTSM_SubTableValGet(MTTSM_InputBaseFolder,MTTSM_InputBaseFolder[i][1],0,2))
                choice = i
            end
        end
        imgui.EndCombo()
    end
    MTTSM_ItemTooltip("The base folder from which the location of the input text file is defined. Absolute path on *your system*:\n"..MTTSM_PathConstructor(MTTSM_InterfaceSelected,"Input","Base"))
    --MTTSM_ItemTooltip("The text file the plugin writes its MaryTTS information into. Currently set to:\n"..MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,3))
    imgui.TextUnformatted(editstring.."Input Text File ") imgui.SameLine()
    local changed,buffer = imgui.InputText("##Input"..MTTSM_InterfaceSelected,MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,3), 1024)
    if MTTSM_InterfaceEditMode == 1 then if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Input",0,3,tostring(buffer)) buffer = nil end end
    MTTSM_ItemTooltip("The location and filename of the input text file relative to the base folder above. The complete, absolute path on *your system*:\n"..MTTSM_PathConstructor(MTTSM_InterfaceSelected,"Input","Full"))
    imgui.TextUnformatted(editstring.."Input Delimiter ") imgui.SameLine()
    local changed,buffer = imgui.InputText("##Delimiter"..MTTSM_InterfaceSelected,MTTSM_SubTableValGet(inputtable[tabindex][2],"Input",0,4), 1024)
    if MTTSM_InterfaceEditMode == 1 then if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Input",0,4,tostring(buffer)) buffer = nil end end
    MTTSM_ItemTooltip("The sign that is used to separate voice and string to be spoken in the text file.")
    imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
    imgui.TextUnformatted(editstring.."Output Base Path") imgui.SameLine()
    if imgui.BeginCombo("##ComboOutputWAV",MTTSM_SubTableValGet(inputtable[tabindex][2],"Output",0,2)) then
        for i = 1, #MTTSM_InputBaseFolder do
            if imgui.Selectable(MTTSM_InputBaseFolder[i][1], choice == i) then
                MTTSM_SubTableValSet(inputtable[tabindex][2],"Output",0,2,MTTSM_InputBaseFolder[i][1])
                --print(MTTSM_SubTableValGet(inputtable[tabindex][2],"Output",0,2).." -> "..MTTSM_SubTableValGet(MTTSM_InputBaseFolder,MTTSM_InputBaseFolder[i][1],0,2))
                choice = i
            end
        end
        imgui.EndCombo()
    end
    MTTSM_ItemTooltip("The base folder from which the location of the output WAV file is defined. Absolute path on *your system*:\n"..MTTSM_PathConstructor(MTTSM_InterfaceSelected,"Output","Base"))    
    imgui.TextUnformatted(editstring.."Output WAV File ") imgui.SameLine()
    local changed,buffer = imgui.InputText("##Output"..MTTSM_InterfaceSelected,MTTSM_SubTableValGet(inputtable[tabindex][2],"Output",0,3), 1024)
    if MTTSM_InterfaceEditMode == 1 then if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Output",0,3,tostring(buffer)) buffer = nil end end
    MTTSM_ItemTooltip("The location and filename of the output WAV file relative to the base folder above. The complete, absolute path on *your system*:\n"..MTTSM_PathConstructor(MTTSM_InterfaceSelected,"Output","Full"))
    imgui.TextUnformatted(editstring.."Play WAV With   ") imgui.SameLine()
    if imgui.BeginCombo("##ComboPlaybackAgent",MTTSM_SubTableValGet(inputtable[tabindex][2],"Output",0,4)) then
        for i = 1, #MTTSM_PlaybackAgent do
            if imgui.Selectable(MTTSM_PlaybackAgent[i], choice == i) then
                MTTSM_SubTableValSet(inputtable[tabindex][2],"Output",0,4,MTTSM_PlaybackAgent[i])
                choice = i
            end
        end
        imgui.EndCombo()
    end
    MTTSM_ItemTooltip("The agent that plays back the output WAV file.")  
    imgui.PopItemWidth()
    if MTTSM_InterfaceSelected ~= MTTSM_InterfaceContainer[1][1] then
        if MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") > 1 then
            for j=2,MTTSM_SubTableLength(inputtable[tabindex][2],"Voicemap") do
                imgui.PushItemWidth(MTTSM_SettingsValGet("Window_W")-370)
                imgui.TextUnformatted(editstring.."Voice Mapping "..string.format("%02d",(j-1))) imgui.SameLine()
                local changed,buffer = imgui.InputText("##Mapping"..MTTSM_InterfaceSelected..(j-1),MTTSM_SubTableValGet(inputtable[tabindex][2],"Voicemap",j,1), 256)
                if MTTSM_InterfaceEditMode == 1 then if changed and buffer ~= "" and tostring(buffer) then MTTSM_SubTableValSet(inputtable[tabindex][2],"Voicemap",j,1,tostring(buffer)) buffer = nil end end
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
            MTTSM_ItemTooltip("Save interface file to "..MTTSM_InterfFolder.."/"..inputtable[tabindex][2][1][1]..".cfg")
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
    if MTTSM_InterfaceSelected ~= MTTSM_InterfaceContainer[1][1] and imgui.Button(buttonstring.." Edit Mode",(MTTSM_SettingsValGet("Window_W")-59),20) then if MTTSM_InterfaceEditMode == 0 then MTTSM_InterfaceEditMode = 1 else MTTSM_InterfaceEditMode = 0 end end
    if buttonstring == "Enable" then MTTSM_ItemTooltip("Enter interface edit mode (will stop input text file processing watchdog!)") end
    if buttonstring == "Disable" then MTTSM_ItemTooltip("Leave interface edit mode (will (re)start input text file processing watchdog!)") end
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
        MTTSM_ItemTooltip("The string that is to be spoken.")
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
        MTTSM_ItemTooltip("The voice actor that speaks the above string.")
        --imgui.TextUnformatted("Volume/Filter:        ") --imgui.SameLine()
        --imgui.SameLine() imgui.Dummy((MTTSM_SettingsValGet("Window_W")-395),20) imgui.SameLine()
        --imgui.Dummy(MTTSM_SettingsValGet("Window_W")-180,5)
        imgui.Dummy(19,20) imgui.SameLine()
        if imgui.Button("Speak",MTTSM_SettingsValGet("Window_W")-59,20) then MTTSM_OutputToFile(MTTSM_InterfaceContainer[1][1],MTTSM_VoiceSelected,MTTSM_TestString) end
        MTTSM_ItemTooltip("Speaks the string with the selected voice.")
    else
        imgui.Dummy(19,20) imgui.SameLine()
        imgui.TextUnformatted("MaryTTS server is not running; testing area disabled!")
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),40)
    end
    imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),20)
end
--[[ 

INITIALIZATION

]]
function MTTSM_ModuleInit_Main()
    if MTTSM_SettingsValGet("AutoLoad") == 1 then 
        --MTTSM_Log_Write(MTTSM_PageTitle..": Autoloading values from "..MTTSM_Module_SaveFile) 
        --MTTSM_FileRead(MTTSM_Module_SaveFile,MTTSM_InterfaceData)
        
    end
    MTTSM_InterfaceLoad(MTTSM_InterfFolder,MTTSM_InterfaceContainer,MTTSM_InterfaceData) 
    MTTSM_GetFileList(MTTSM_MaryFolder.."/installed",MTTSM_VoiceList,"voice")
    MTTSM_FindActiveInterfaces(MTTSM_InterfaceContainer)
end
--[[ 

IMGUI WINDOW ELEMENT

]]
--[[ Window page initialization ]]
local function MTTSM_Page_Init()
    if MTTSM_PageInitStatus == 0 then MTTSM_Refresh_PageDB(MTTSM_PageTitle) MTTSM_PageInitStatus = 1 end
end
--[[ Window content ]]
function MTTSM_Win_Main()
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
        -- Server status display
        imgui.Dummy(19,20) imgui.SameLine()
        imgui.TextUnformatted("MaryTTS Server Status: "..MTTSM_Status)
        if MTTSM_Process ~= nil then imgui.SameLine() imgui.TextUnformatted("(PID: "..MTTSM_Process..")")
        if MTTSM_InterfaceEditMode == 1 then imgui.SameLine() imgui.TextUnformatted(", watchdog disabled!") end end
        --imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
        -- Server control button
        imgui.Dummy(19,20) imgui.SameLine()
        if imgui.Button("Check MaryTTS' Process",(MTTSM_SettingsValGet("Window_W")-59),20) then
            MTTSM_CheckProc()
        end
        MTTSM_ItemTooltip("Scans the running processes for the MaryTTS server and returns the process ID if it is found.")
        imgui.Dummy(19,20) imgui.SameLine()
        if MTTSM_Process == nil and imgui.Button("Start MaryTTS Server",(MTTSM_SettingsValGet("Window_W")-59),20) then
            MTTSM_Server_Start()
        end
        if MTTSM_Process == nil then MTTSM_ItemTooltip("Starts the MaryTTS server.") end
        if MTTSM_Process ~= nil and imgui.Button("Stop MaryTTS Server",(MTTSM_SettingsValGet("Window_W")-59),20) then
            MTTSM_Server_Stop()
        end
        if MTTSM_Process ~= nil then MTTSM_ItemTooltip("Stops the MaryTTS server.") end
    --[[ End page ]]    
    end
end
