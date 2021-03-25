--[[

Lua Module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

VARIABLES (local to this module)

]]
--[[ Dataref table: Name, dataref, array length, current value(s) ]]
MTTSM_DataRefTable = {
{"Num Engines","sim/aircraft/engine/acf_num_engines",1,{}},
--{"Engine RPM","sim/cockpit2/engine/indicators/engine_speed_rpm",8,{}},
{"Batteries","sim/cockpit/electrical/battery_array_on",8,{}},
{"Wt_Empty","sim/aircraft/weight/acf_m_empty",1,{}},
    
    
}

--[[

FUNCTIONS

]]
--[[ Read/Write Accessor: Update a dataref's value in/from the target/input table ]]
local function MTTSM_DataRefUpdate(intable,index,mode)
    local dref = XPLMFindDataRef(intable[index][2])
    if dref ~= nil then
        local dreftype = XPLMGetDataRefTypes(dref)
        if mode == "r" then
            if dreftype == 1 then intable[index][4][0] = XPLMGetDatai(dref) end
            if dreftype == 2 then intable[index][4][0] = XPLMGetDataf(dref) end
            if dreftype == 4 then intable[index][4][0] = XPLMGetDatad(dref) end
            if dreftype == 8  then intable[index][4] = XPLMGetDatavf(dref,0,intable[index][3]) end
            if dreftype == 16 then intable[index][4] = XPLMGetDatavi(dref,0,intable[index][3]) end
            --print(intable[index][1].." : "..table.concat(intable[index][4],", ",0))
        elseif mode == "w" then
            if dreftype == 1 then XPLMSetDatai(dref,intable[index][4][0]) end
            if dreftype == 2 then XPLMSetDataf(dref,intable[index][4][0]) end
            if dreftype == 4 then XPLMSetDatad(dref,intable[index][4][0]) end
            if dreftype == 8  then XPLMSetDatavf(dref,intable[index][4],0,intable[index][3]) end
            if dreftype == 16 then XPLMSetDatavi(dref,intable[index][4],0,intable[index][3]) end
        end
    end
end
--[[ Read Wrapper: Update dataref table or update and return a specific value ]]
function MTTSM_DatarefRead(intable,target,index)
    for i=1,#intable do
        if target == "[All]" then 
            MTTSM_DataRefUpdate(intable,i,"r")
        elseif intable[i][1] == target then
            MTTSM_DataRefUpdate(intable,i,"r")
            if index == nil then return intable[i][4][0]
            else return intable[i][4][index-1] end
        end
    end
end
--[[ Read Wrapper: Access a stored value from the dataref table ]]
function MTTSM_DatarefTableRead(intable,target,index)
    for i=1,#intable do
        if intable[i][1] == target then
            if #intable[i][4] == 0 then MTTSM_DataRefUpdate(intable,i,"r") end
            if index == nil then return intable[i][4][0]
            else return intable[i][4][index-1] end
        end
    end
end
--[[ Write Wrapper: Write a value to the dataref storage table ]]
function MTTSM_DatarefTableWrite(intable,target,index,input)
    for i=1,#intable do
        if intable[i][1] == target then
            if #intable[i][4] == 0 then MTTSM_DataRefUpdate(intable,i,"r") end
            if index == nil then intable[i][4][0] = input MTTSM_DataRefUpdate(intable,i,"w")
            else intable[i][4][index-1] = input MTTSM_DataRefUpdate(intable,i,"w") end
        end
    end
end
