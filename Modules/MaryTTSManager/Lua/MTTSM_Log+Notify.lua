--[[

Lua Module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

VARIABLES (local to this module)

]]
local MTTSM_LogFile = MODULES_DIRECTORY.."MaryTTSManager/Log.txt"          -- Log file path
MTTSM_NotificationStack = { }                     -- Array for the notification stack 
local toremove = {}
--[[

FUNCTIONS

]]
--[[ Write to log file ]]
function MTTSM_Log_Write(string)
	local file = io.open(MTTSM_LogFile, "a") -- Check if file exists
	file:write(os.date("%x, %H:%M:%S"),": ",string,"\n")
	file:close()
end
--[[ Delete log file ]]
function MTTSM_Log_Delete()
    os.remove(MTTSM_LogFile) MTTSM_Notification("FILE DELETE: "..MTTSM_LogFile,"Warning","log")
end
--[[ Available types: "Success","Advisory","Warning","Error"]]
function MTTSM_Notification(messagestring,messagetype,writelog)
    MTTSM_NotificationStack[(#MTTSM_NotificationStack+1)] = {}
    MTTSM_NotificationStack[#MTTSM_NotificationStack][1] = messagestring
    MTTSM_NotificationStack[#MTTSM_NotificationStack][2] = messagetype
    MTTSM_NotificationStack[#MTTSM_NotificationStack][3] = os.clock() + MTTSM_SettingsValGet("NotificationDispTime")
    --print(table.concat(MTTSM_NotificationStack[#MTTSM_NotificationStack],";",1,#MTTSM_NotificationStack[#MTTSM_NotificationStack]))
    if writelog == "log" then
        MTTSM_Log_Write(messagestring)
    end
end
--[[ 

IMGUI WINDOW ELEMENT

]]
function MTTSM_Win_Notifications()
    --------------------------------------------------------
	imgui.Separator()
	--------------------------------------------------------
    imgui.TextUnformatted("Notifications:")
    -- Only display when message stack table is empty
    if #MTTSM_NotificationStack == 0 then
        imgui.TextUnformatted("(None)")
    end
    -- Loop through stack, see if a stack message is valid, then display it colored according to type. If not valid anymore, mark it for deletion by noting the subtable index
    for k=1,#MTTSM_NotificationStack do
        if os.clock() <= MTTSM_NotificationStack[k][3] then
            if tostring(MTTSM_NotificationStack[k][2]) == "Success" then imgui.PushStyleColor(imgui.constant.Col.Text, MTTSM_ImguiColors[5]) imgui.TextUnformatted(MTTSM_NotificationStack[k][1]) imgui.PopStyleColor()
            elseif tostring(MTTSM_NotificationStack[k][2]) == "Advisory" then imgui.PushStyleColor(imgui.constant.Col.Text, MTTSM_ImguiColors[6]) imgui.TextUnformatted(MTTSM_NotificationStack[k][1]) imgui.PopStyleColor() 
            elseif tostring(MTTSM_NotificationStack[k][2]) == "Warning" then imgui.PushStyleColor(imgui.constant.Col.Text, MTTSM_ImguiColors[7]) imgui.TextUnformatted(MTTSM_NotificationStack[k][1]) imgui.PopStyleColor()
            elseif tostring(MTTSM_NotificationStack[k][2]) == "Error" then imgui.PushStyleColor(imgui.constant.Col.Text, MTTSM_ImguiColors[4]) imgui.TextUnformatted(MTTSM_NotificationStack[k][1]) imgui.PopStyleColor() end
        else
            toremove[#toremove+1] = k
        end
    end
    -- If index table for deletion is not empty, loop through it and delete the subtable from the message stack table by index
    if #toremove > 0 then
        for l=1,#toremove do
            table.remove(MTTSM_NotificationStack,toremove[l])
            --imgui.TextUnformatted(toremove[l])
            toremove = {}
        end
    end
end
