--[[

Lua module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

MENU LABELS, ITEMS AND ACTIONS

]]
local Menu_Name = "MaryTTS Manager" -- Menu title
local Menu_Items = {" Window","[Separator]","Autoload Settings","[Separator]","MaryTTS Server","Autostart MaryTTS Server"}  -- Menu entries, index starts at 1
--[[ Menu item callbacks ]]
local function Menu_Callback(itemref)
    if itemref == Menu_Items[1] then 
        if MTTSM_SettingsValGet("WindowIsOpen") == 0 then MTTSM_Window_Show()
        elseif MTTSM_SettingsValGet("WindowIsOpen") == 1 then MTTSM_Window_Hide(MTTSM_Window) end
        MTTSM_Menu_Watchdog(1)
    end
    if itemref == Menu_Items[3] then 
        if MTTSM_SettingsValGet("AutoLoad") == 0 then MTTSM_SettingsValSet("AutoLoad",1) MTTSM_SettingsFileWrite()
        elseif MTTSM_SettingsValGet("AutoLoad") == 1 then MTTSM_SettingsValSet("AutoLoad",0) MTTSM_SettingsFileWrite() end
        MTTSM_Menu_Watchdog(3)
    end
    if itemref == Menu_Items[5] then
        if MTTSM_Status == "Stopped" then MTTSM_Server_Start()
        elseif MTTSM_Status == "Running" then MTTSM_Server_Stop() end
        MTTSM_Menu_Watchdog(5)
    end
    if itemref == Menu_Items[6] then
        if MTTSM_SettingsValGet("AutostartServer") == 0 then MTTSM_SettingsValSet("AutostartServer",1) MTTSM_SettingsFileWrite() MTTSM_Log_Write("MaryTTS Server: Autostart enabled")
        elseif MTTSM_SettingsValGet("AutostartServer") == 1 then MTTSM_SettingsValSet("AutostartServer",0) MTTSM_SettingsFileWrite() MTTSM_Log_Write("MaryTTS Server: Autostart disabled") end
        MTTSM_Menu_Watchdog(6)
    end
end
--[[

INITIALIZATION

]]
local Menu_Indices = {}
for i=1,#Menu_Items do 
    Menu_Indices[i] = 0 
end
--[[

MENU INITALIZATION AND CLEANUP

]]
--[[ Variables for FFI ]]
local Menu_Pointer = MTTSM_ffi.new("const char")
--[[ Menu initialization ]]
function MTTSM_Menu_Init()
    if MTTSM_XPLM ~= nil then
        MTTSM_Menu_Index = MTTSM_XPLM.XPLMAppendMenuItem(MTTSM_XPLM.XPLMFindPluginsMenu(),Menu_Name,MTTSM_ffi.cast("void *","None"),1)
        MTTSM_Menu_ID = MTTSM_XPLM.XPLMCreateMenu(Menu_Name,MTTSM_XPLM.XPLMFindPluginsMenu(),MTTSM_Menu_Index, function(inMenuRef,inItemRef) Menu_Callback(inItemRef) end,MTTSM_ffi.cast("void *",Menu_Pointer))
        for i=1,#Menu_Items do
            if Menu_Items[i] ~= "[Separator]" then
                Menu_Pointer = Menu_Items[i]
                Menu_Indices[i] = MTTSM_XPLM.XPLMAppendMenuItem(MTTSM_Menu_ID,Menu_Items[i],MTTSM_ffi.cast("void *",Menu_Pointer),1)
            else
                MTTSM_XPLM.XPLMAppendMenuSeparator(MTTSM_Menu_ID)
            end
        end
        MTTSM_Menu_Watchdog(1)        -- Watchdog for menu item 1
        MTTSM_Menu_Watchdog(3)        -- Watchdog for menu item 3
        MTTSM_Menu_Watchdog(5)        -- Watchdog for menu item 5
        MTTSM_Menu_Watchdog(6)        -- Watchdog for menu item 6
        MTTSM_Log_Write("INIT: "..Menu_Name.." menu initialized!")
    end
end
--[[ Menu cleanup upon script reload or session exit ]]
function MTTSM_Menu_CleanUp()
   MTTSM_XPLM.XPLMClearAllMenuItems(MTTSM_Menu_ID)
   MTTSM_XPLM.XPLMDestroyMenu(MTTSM_Menu_ID)
   MTTSM_XPLM.XPLMRemoveMenuItem(MTTSM_XPLM.XPLMFindPluginsMenu(),MTTSM_Menu_Index)
end
--[[

MENU MANIPULATION WRAPPERS

]]
--[[ Menu item name change ]]
local function MTTSM_Menu_ChangeItemPrefix(index,prefix)
    MTTSM_XPLM.XPLMSetMenuItemName(MTTSM_Menu_ID,index-1,prefix.." "..Menu_Items[index],1)
end
--[[ Menu item check status change ]]
function MTTSM_Menu_CheckItem(index,state)
    index = index - 1
    local out = MTTSM_ffi.new("XPLMMenuCheck[1]")
    MTTSM_XPLM.XPLMCheckMenuItemState(MTTSM_Menu_ID,index-1,MTTSM_ffi.cast("XPLMMenuCheck *",out))
    if tonumber(out[0]) == 0 then MTTSM_XPLM.XPLMCheckMenuItem(MTTSM_Menu_ID,index,1) end
    if state == "Activate" and tonumber(out[0]) ~= 2 then MTTSM_XPLM.XPLMCheckMenuItem(MTTSM_Menu_ID,index,2)
    elseif state == "Deactivate" and tonumber(out[0]) ~= 1 then MTTSM_XPLM.XPLMCheckMenuItem(MTTSM_Menu_ID,index,1)
    end
end
--[[ Watchdog to track window state changes ]]
function MTTSM_Menu_Watchdog(index)
    if index == 1 then
        if MTTSM_SettingsValGet("WindowIsOpen") == 0 then MTTSM_Menu_ChangeItemPrefix(index,"Open")
        elseif MTTSM_SettingsValGet("WindowIsOpen") == 1 then MTTSM_Menu_ChangeItemPrefix(index,"Close") end
    end
    if index == 3 then
        if MTTSM_SettingsValGet("AutoLoad") == 0 then MTTSM_Menu_CheckItem(index,"Deactivate")
        elseif MTTSM_SettingsValGet("AutoLoad") == 1 then MTTSM_Menu_CheckItem(index,"Activate") end
    end
    if index == 5 then
        if MTTSM_Status == "Stopped" then MTTSM_Menu_ChangeItemPrefix(index,"Start")
        elseif MTTSM_Status == "Starting" then MTTSM_Menu_ChangeItemPrefix(index,"[Starting]")
        elseif MTTSM_Status == "Running" then MTTSM_Menu_ChangeItemPrefix(index,"Stop")
        elseif MTTSM_Status == "Stopping" then MTTSM_Menu_ChangeItemPrefix(index,"[Stopping]")
        end
    end
    if index == 6 then
        if MTTSM_SettingsValGet("AutostartServer") == 0 then MTTSM_Menu_CheckItem(index,"Deactivate")
        elseif MTTSM_SettingsValGet("AutostartServer") == 1 then MTTSM_Menu_CheckItem(index,"Activate") end
    end
end
