--[[

Lua module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

MENU LABELS, ITEMS AND ACTIONS

]]
local Menu_Name = "MaryTTS Manager" -- Menu title
local Menu_Items = {" Window","[Separator]","Autoload Settings"}  -- Menu entries, index starts at 1
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
local Menu_ID = nil
local Menu_Pointer = MTTSM_ffi.new("const char")
--[[ Menu initialization ]]
function MTTSM_Menu_Init()
    if MTTSM_XPLM ~= nil then
        Menu_ID = MTTSM_XPLM.XPLMCreateMenu(Menu_Name,nil,0, function(inMenuRef,inItemRef) Menu_Callback(inItemRef) end,MTTSM_ffi.cast("void *",Menu_Pointer))
        for i=1,#Menu_Items do
            if Menu_Items[i] ~= "[Separator]" then
                Menu_Pointer = Menu_Items[i]
                Menu_Indices[i] = MTTSM_XPLM.XPLMAppendMenuItem(Menu_ID,Menu_Items[i],MTTSM_ffi.cast("void *",Menu_Pointer),1)
            else
                MTTSM_XPLM.XPLMAppendMenuSeparator(Menu_ID)
            end
        end
        MTTSM_Menu_Watchdog(1)        -- Watchdog for menu item 1
        MTTSM_Menu_Watchdog(3)        -- Watchdog for menu item 3
        MTTSM_Log_Write("INIT: "..Menu_Name.." menu initialized!")
    end
end
--[[ Menu cleanup upon script reload or session exit ]]
function MTTSM_Menu_CleanUp()
   MTTSM_XPLM.XPLMClearAllMenuItems(MTTSM_XPLM.XPLMFindPluginsMenu())
   --MTTSM_XPLM.XPLMDestroyMenu(Menu_ID)
end
--[[

MENU MANIPULATION WRAPPERS

]]
--[[ Menu item name change ]]
local function MTTSM_Menu_ChangeItemPrefix(index,prefix)
    MTTSM_XPLM.XPLMSetMenuItemName(Menu_ID,index-1,prefix.." "..Menu_Items[index],1)
end
--[[ Menu item check status change ]]
function MTTSM_Menu_CheckItem(index,state)
    index = index - 1
    local out = MTTSM_ffi.new("XPLMMenuCheck[1]")
    MTTSM_XPLM.XPLMCheckMenuItemState(Menu_ID,index-1,MTTSM_ffi.cast("XPLMMenuCheck *",out))
    if tonumber(out[0]) == 0 then MTTSM_XPLM.XPLMCheckMenuItem(Menu_ID,index,1) end
    if state == "Activate" and tonumber(out[0]) ~= 2 then MTTSM_XPLM.XPLMCheckMenuItem(Menu_ID,index,2)
    elseif state == "Deactivate" and tonumber(out[0]) ~= 1 then MTTSM_XPLM.XPLMCheckMenuItem(Menu_ID,index,1)
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
end
