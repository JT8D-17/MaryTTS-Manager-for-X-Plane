--[[ 

MaryTTS Manager
Licensed under the EUPL v1.2: https://eupl.eu/

BK, xxyyzzzz
 ]]
--[[

REQUIREMENTS

]]
if not SUPPORTS_FLOATING_WINDOWS then
	print("Imgui not supported by your FlyWithLua version. Please update to the latest release")
	return
end
--[[ Required modules,DO NOT MODIFY LOAD ORDER! ]]
MTTSM_ffi = require ("ffi")                     -- LuaJIT FFI module
require("MaryTTSManager/Lua/MTTSM_Log+Notify")   -- Imgui Window Element: Notifications
require("MaryTTSManager/Lua/MTTSM_Common")       -- Imgui Window Element: FileIO
require("MaryTTSManager/Lua/MTTSM_Settings")     -- Imgui Window Element: Settings
require("MaryTTSManager/Lua/MTTSM_Datarefs")     -- Datarefs and accessors
require("MaryTTSManager/Lua/MTTSM_Menu")         -- Menu entries for the plugins menu
require("MaryTTSManager/Lua/MTTSM_Main")         -- MaryTTS manager main module
--[[

VARIABLES (local or global)

]]
MTTSM_ScriptName = "MaryTTS Manager"   -- Name of the script
local MTTSM_PageTitle = "Main Menu"   -- Main menu page title - DO NOT EDIT!
local MTTSM_Initialized = false       -- Has the script been initialized?
local MTTSM_PageInitStatus = 0        -- Has the window been initialized?
MTTSM_Check_Autoload = false          -- Enables check of the autoloading condition
MTTSM_Window_Pos={0,0}                -- Window position x,y
MTTSM_ImguiColors={0x33FFAE00,0xBBFFAE00,0xFFC8C8C8,0xFF0000FF,0xFF19CF17,0xFFB6CDBA,0xFF40aee5} -- Imgui: Control elements passive, control elements active, text, negative, positive, neutral, caution
MTTSM_Menu_ID = nil                   -- ID of the main MTTSM menu
MTTSM_Menu_Index = nil                -- Index of the MTTSM menu in the plugins menu
--[[

INITIALIZATION

]]
local function MTTSM_Main_Init()
    MTTSM_Log_Delete()					-- Delete the old log file
    MTTSM_Log_Write("INIT: Beginning "..MTTSM_ScriptName.." initialization")
    MTTSM_SettingsFileRead() 				-- Trigger reading the UI settings file
    if MTTSM_SettingsValGet("WindowIsOpen") == 1 then MTTSM_Window_Show() end -- If window open flag was true, build the window
    MTTSM_Menu_Init()
    MTTSM_ModuleInit_Main()
    MTTSM_Initialized = true
    if MTTSM_Initialized then print("---> "..MTTSM_ScriptName.." initialized.") MTTSM_Log_Write("INIT: Finished "..MTTSM_ScriptName.." initialization") end
end
--[[

FUNCTIONS

]]
--[[ Show Window ]]
function MTTSM_Window_Show()
	MTTSM_Window = float_wnd_create(MTTSM_SettingsValGet("Window_W"), MTTSM_SettingsValGet("Window_H"), 1, true)
	float_wnd_set_position(MTTSM_Window, MTTSM_SettingsValGet("Window_X"), MTTSM_SettingsValGet("Window_Y"))
	float_wnd_set_title(MTTSM_Window, MTTSM_ScriptName)
	float_wnd_set_imgui_builder(MTTSM_Window, "MTTSM_Window_Build")
	float_wnd_set_onclose(MTTSM_Window, "MTTSM_Window_Hide")
	MTTSM_SettingsValSet("WindowIsOpen",1)
	MTTSM_Settings_CheckAutosave()
	--print("Window open: "..MTTSM_SettingsValGet("WindowIsOpen"))
	MTTSM_Log_Write("Window Opening")
    MTTSM_Menu_Watchdog(1)
end
--[[ Hide Window ]]
function MTTSM_Window_Hide(MTTSM_Window)
	if MTTSM_Window then float_wnd_destroy(MTTSM_Window) end
	MTTSM_SettingsValSet("WindowIsOpen",0)
	MTTSM_Settings_CheckAutosave()
	--print("Window open: "..MTTSM_SettingsValGet("WindowIsOpen"))
	MTTSM_Log_Write("Window Closing")
    MTTSM_Menu_Watchdog(1)
end
--[[ Toggle Window ]]
function MTTSM_Window_Toggle()
	if MTTSM_SettingsValGet("WindowIsOpen") == 0  then MTTSM_Window_Show() else MTTSM_Window_Hide(MTTSM_Window) end
end
--[[ Open Window by Keystroke ]]
function MTTSM_Window_By_Key()
	if MTTSM_SettingsValGet("WindowToggleByHotkey") == 1 and KEY_ACTION=="pressed" and VKEY==MTTSM_SettingsValGet("WindowToggleHotkey") then
		MTTSM_Window_Toggle()
		RESUME_KEY = true
		--print("Pressed "..MTTSM_SettingsValGet("WindowToggleHotkey"))
	end
end
do_on_keystroke("MTTSM_Window_By_Key()")
--[[ Open Window and switch to page ]]
function MTTSM_Window_GoTo(inpage)
    if MTTSM_SettingsValGet("WindowIsOpen") == 0 then MTTSM_Window_Show() end 
    MTTSM_SettingsValSet("Window_Page",inpage)
end
--[[ Asset: "Main Menu" button ]]
function MTTSM_Win_Button_Back(target)
    if imgui.Button(target,(MTTSM_SettingsValGet("Window_W")-30),20) then
        MTTSM_SettingsValSet("Window_Page",MTTSM_PageNumGet(target)) 
        float_wnd_set_title(MTTSM_Window, MTTSM_ScriptName)
        MTTSM_Settings_CheckAutosave()
    end
    MTTSM_ItemTooltip("Return to "..target)
    imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
    imgui.Separator()
end
--[[ 

IMGUI WINDOW ELEMENT

]]
--[[ Page initialization ]]
local function MTTSM_Page_Init()
    if MTTSM_PageInitStatus == 0 then MTTSM_Refresh_PageDB(MTTSM_PageTitle) 
        if MTTSM_SettingsValGet("AutoLoad") ~= 1 or MTTSM_SettingsValGet("Window_Page") == 0 then MTTSM_SettingsValSet("Window_Page",MTTSM_PageNumGet(MTTSM_PageTitle)) end
    MTTSM_PageInitStatus = 1 end
end
--[[ Imgui window builder ]]
function MTTSM_Window_Build(MTTSM_Window,xpos,ypos)
	MTTSM_Window_Pos={xpos,ypos}
	--[[ Window styling ]]
	imgui.PushStyleColor(imgui.constant.Col.Button,MTTSM_ImguiColors[1])
	imgui.PushStyleColor(imgui.constant.Col.ButtonHovered,MTTSM_ImguiColors[2])
	imgui.PushStyleColor(imgui.constant.Col.ButtonActive,MTTSM_ImguiColors[2])
	imgui.PushStyleColor(imgui.constant.Col.Text,MTTSM_ImguiColors[3])
	imgui.PushStyleColor(imgui.constant.Col.TextSelectedBg,MTTSM_ImguiColors[2])
	imgui.PushStyleColor(imgui.constant.Col.FrameBg,MTTSM_ImguiColors[1])
	imgui.PushStyleColor(imgui.constant.Col.FrameBgHovered,MTTSM_ImguiColors[2])
	imgui.PushStyleColor(imgui.constant.Col.FrameBgActive,MTTSM_ImguiColors[2])
	imgui.PushStyleColor(imgui.constant.Col.Header,MTTSM_ImguiColors[1])
	imgui.PushStyleColor(imgui.constant.Col.HeaderActive,MTTSM_ImguiColors[2])
	imgui.PushStyleColor(imgui.constant.Col.HeaderHovered,MTTSM_ImguiColors[2])
	imgui.PushStyleColor(imgui.constant.Col.CheckMark,MTTSM_ImguiColors[3])
    imgui.PushTextWrapPos(MTTSM_SettingsValGet("Window_W")-30)
    imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
	--[[ Window Content ]]
    MTTSM_Win_Main()
	MTTSM_Win_Settings()
    imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
    MTTSM_Win_Notifications()
	--[[ End Window Styling ]]
	imgui.PopStyleColor(12)
    imgui.PopTextWrapPos()
    --[[ Check page init status ]]
    MTTSM_Page_Init()
    --[[ Page ]]
    if MTTSM_SettingsValGet("Window_Page") == MTTSM_PageNumGet(MTTSM_PageTitle) then
        --[[ Set the page title ]]
        float_wnd_set_title(MTTSM_Window, MTTSM_ScriptName.." ("..MTTSM_PageTitle..")")
    end
--[[ End Imgui Window ]]
end
--[[

INITIALIZATION

]]
--[[ Has to run in a 1 second loop to work ]]
function MTTSM_Main_1sec()
    if not MTTSM_Initialized then 
        MTTSM_Main_Init()
    else
        MTTSM_Watchdog()
    end
end
do_often("MTTSM_Main_1sec()")
--[[

EXIT

]]
do_on_exit("MTTSM_Server_Stop()")
do_on_exit("MTTSM_Menu_CleanUp()")
--[[

MACROS AND COMMANDS

]]
add_macro("MaryTTS Manager: Toggle Window", "MTTSM_Window_Show()","MTTSM_Window_Hide(MTTSM_Window)","deactivate")
create_command("MaryTTS Manager/Window/Toggle", "Toggle Window", "MTTSM_Window_Toggle()", "", "")
