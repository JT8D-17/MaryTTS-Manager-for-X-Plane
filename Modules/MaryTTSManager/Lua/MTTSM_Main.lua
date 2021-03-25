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
local MTTSM_Module_Vars = {
{"MaryTTS"},           -- SAVE FILE IDENTIFIER; KEEP UNIQUE TO THIS ARRAY
--{"DateSync",0},       -- Formatting examples
--{"Loans"},
--{"BestLanding",{0,"XXXX"}},
}
local MTTSM_BaseFolder = MODULES_DIRECTORY.."MaryTTSManager/Resources/"
local MTTSM_JREFolder = MTTSM_BaseFolder.."JRE/Linux/jdk-11.0.7+10-jre/bin/"
local MTTSM_MaryFolder = MTTSM_BaseFolder.."/marytts-5.2"
local MTTSM_ServerLog = MTTSM_MaryFolder.."/log/server.log"
local MTTSM_Log = MTTSM_BaseFolder.."/Log_MaryTTS.txt"
local MTTSM_Handle = "marytts.server.Mary"
local MTTSM_OutputWav = MTTSM_BaseFolder.."/transmission.wav"
local MTTSM_Process = nil
local MTTSM_Status = "Stopped"
local MTTSM_SpeakString = {"dfki-spike-hsmm","Hello, I am a TTS voice."}
--[[

FUNCTIONS

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
--[[ ]]
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
        --MTTSM_FileRead(MTTSM_Module_SaveFile,MTTSM_Module_Vars)
    end
end
--[[ 

IMGUI WINDOW ELEMENT

]]
--[[ Window page initialization ]]
local function MTTSM_Page_Init()
    if MTTSM_PageInitStatus == 0 then MTTSM_Refresh_PageDB(MTTSM_PageTitle) MTTSM_PageInitStatus = 1 end
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
        imgui.TextUnformatted("MaryTTS server status: "..MTTSM_Status)
        if MTTSM_Process ~= nil then imgui.SameLine() imgui.TextUnformatted("(Process ID: "..MTTSM_Process..")") end
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
        if MTTSM_Process ~= nil and MTTSM_Status == "Running" then
            imgui.PushItemWidth(MTTSM_SettingsValGet("Window_W")-30)
            local changed,buffer = imgui.InputText("##SpeakString",MTTSM_SpeakString[2], 256)
            if changed and buffer ~= "" and tostring(buffer) then MTTSM_SpeakString[2] = buffer buffer = nil end
            imgui.PopItemWidth() imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),5)
            if imgui.Button("Speak",(MTTSM_SettingsValGet("Window_W")-30),20) then MTTSM_ProcessString(MTTSM_SpeakString[1],MTTSM_SpeakString[2]) end
        end
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),20)
        --[[ if imgui.Button("Check MaryTTS Server status",(MTTSM_SettingsValGet("Window_W")-30),20) then
            MTTSM_CheckProc()
        end ]]
        if MTTSM_Process == nil and imgui.Button("Start MaryTTS Server",(MTTSM_SettingsValGet("Window_W")-30),20) then
            MTTSM_Server_Start()
        end
        if MTTSM_Process ~= nil and imgui.Button("Stop MaryTTS Server",(MTTSM_SettingsValGet("Window_W")-30),20) then
            MTTSM_Server_Stop()
        end
    --[[ End page ]]    
    end
end
