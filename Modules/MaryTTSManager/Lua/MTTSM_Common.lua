--[[

Lua Module, required by MaryTTSManager.lua
Licensed under the EUPL v1.2: https://eupl.eu/

]]
--[[

VARIABLES (local to this module)

]]
MTTSM_PageDB = {}                 -- Subpage database, generated at initialization
local MTTSM_PageTitle = "DEBUG: FileIO"   -- Title of the page
local MTTSM_PageInitStatus = 0            -- Has the window been initialized?
local MTTSM_SaveFileDelimiter = "#"       -- The delimiter between value and type in the save file

local TestArray = {
{"TEST"},
--{"SubPage",2},
{"DispUnits","kg","ft"},
{"Item 1", 123},    
{"Item 2", 456},   
--{"Item 3", 789},    
{"Item 4", {"Xyz",555}},
{{"Item 5a",100},{"Item 5b",333}},
}

local TargetFile = MODULES_DIRECTORY.."MaryTTSManager/Lua/IOTest.cfg"

--[[

MODULES

]]
MTTSM_XPLM = nil                              -- Define namespace for XPLM library
--[[ Load XPLM library ]]
MTTSM_Log_Write(string.format("FFI XPLM: Operating system is: %s",MTTSM_ffi.os))
if SYSTEM == "IBM" then MTTSM_XPLM = MTTSM_ffi.load("XPLM_64")  -- Windows 64bit
    elseif SYSTEM == "LIN" then MTTSM_XPLM = MTTSM_ffi.load("Resources/plugins/XPLM_64.so")  -- Linux 64bit (Requires "Resources/plugins/" for some reason)
    elseif SYSTEM == "APL" then MTTSM_XPLM = MTTSM_ffi.load("Resources/plugins/XPLM.framework/XPLM") -- 64bit MacOS (Requires "Resources/plugins/" for some reason)
    else return 
end
if MTTSM_XPLM ~= nil then MTTSM_Log_Write("FFI XPLM: Initialized!") end
--[[

C DEFINITIONS AND VARIABLES

]]
--[[ Add C definitions to FFI ]]
MTTSM_ffi.cdef([[
    /* XPLMUtilities*/
    typedef void *XPLMCommandRef;
    /* XPLMMenus */
    typedef int XPLMMenuCheck;
    typedef void *XPLMMenuID;
    typedef void (*XPLMMenuHandler_f)(void *inMenuRef,void *inItemRef);
    XPLMMenuID XPLMFindPluginsMenu(void);
    XPLMMenuID XPLMFindAircraftMenu(void);
    XPLMMenuID XPLMCreateMenu(const char *inName, XPLMMenuID inParentMenu, int inParentItem, XPLMMenuHandler_f inHandler,void *inMenuRef);
    void XPLMDestroyMenu(XPLMMenuID inMenuID);
    void XPLMClearAllMenuItems(XPLMMenuID inMenuID);
    int XPLMAppendMenuItem(XPLMMenuID inMenu,const char *inItemName,void *inItemRef,int inDeprecatedAndIgnored);
    int XPLMAppendMenuItemWithCommand(XPLMMenuID inMenu,const char *inItemName,XPLMCommandRef inCommandToExecute);
    void XPLMAppendMenuSeparator(XPLMMenuID inMenu);      
    void XPLMSetMenuItemName(XPLMMenuID inMenu,int inIndex,const char *inItemName,int inForceEnglish);
    void XPLMCheckMenuItem(XPLMMenuID inMenu,int index,XPLMMenuCheck inCheck);
    void XPLMCheckMenuItemState(XPLMMenuID inMenu,int index,XPLMMenuCheck *outCheck);
    void XPLMEnableMenuItem(XPLMMenuID inMenu,int index,int enabled);      
    void XPLMRemoveMenuItem(XPLMMenuID inMenu,int inIndex);
    /* XPLMDataAccess - inop because they're dumb cunts and can not be accessed */
    /* typedef void *XPLMDataRef;
    int XPLMGetDatab(XPLMDataRef inDataRef,void *outValue,int inOffset,int inMaxBytes);
    void XPLMSetDatab(XPLMDataRef inDataRef,void *inValue,int inOffset,int inLength); */
    ]])
--[[

FUNCTIONS

]]
--[[ Refresh page database ]]
function MTTSM_Refresh_PageDB(intitle)
    --print(MTTSM_ScriptName..": Updating window page database")
    MTTSM_PageDB[#MTTSM_PageDB+1] = {}
    MTTSM_PageDB[#MTTSM_PageDB][1] = intitle
    MTTSM_PageDB[#MTTSM_PageDB][2] = #MTTSM_PageDB
    --for i=1,#MTTSM_PageDB do
       --print(MTTSM_ScriptName..": "..table.concat(MTTSM_PageDB[i]," : ")) 
    --end
end
--[[ Find page number by title ]]
function MTTSM_PageNumGet(intitle)
    local result
    for i=1,#MTTSM_PageDB do
      if MTTSM_PageDB[i][1] == intitle then result = MTTSM_PageDB[i][2] end
    end
    return result
end

--[[ Accessor: Get sub-table index by finding the value in first field ]]
function MTTSM_SubTableIndex(inputtable,target)
    for i=1,#inputtable do
       if inputtable[i][1] == target then return i end
    end
end

--[[ Accessor: Get sub-table length by finding the value in first field ]]
function MTTSM_SubTableLength(inputtable,target)
    for i=1,#inputtable do
       if inputtable[i][1] == target then return #inputtable[i] end
    end
end

--[[ Accessor: Add sub-table ]]
function MTTSM_SubTableAdd(outputtable,target,inputtable)
    for i=1,#outputtable do
       if outputtable[i][1] == target then
           outputtable[i][#outputtable[i]+1] = inputtable
       end
    end
end

--[[ Accessor: Remove sub-table ]]
function MTTSM_ItemRemove(outputtable,target,index)
    for i=1,#outputtable do
       if outputtable[i][1] == target then
           outputtable[i][index] = nil
       end
    end
end

--[[ Accessor: Get indexed sub-table value by finding the value in first field, consider further subtables ]]
function MTTSM_SubTableValGet(inputtable,target,subtabindex,index)
    for i=1,#inputtable do
       if inputtable[i][1] == target then
           if subtabindex > 0 and subtabindex ~= nil then
                return inputtable[i][subtabindex][index]
            else
                return inputtable[i][index]
           end
       end
    end
end

--[[ Accessor: Set indexed sub-table value by finding the target value in first field, consider further subtables ]]
function MTTSM_SubTableValSet(outputtable,target,subtabindex,index,newvalue)
    for i=1,#outputtable do
       if outputtable[i][1] == target then
           if subtabindex > 0 and subtabindex ~= nil then
                outputtable[i][subtabindex][index] = newvalue
            else
                outputtable[i][index] = newvalue
           end
       end
    end
end

--[[ Writes a file ]]
function MTTSM_FileWrite(inputtable,outputfile,log)
    local temptable = { }
    MTTSM_Log_Write("FILE INIT WRITE: "..outputfile)
    local file = io.open(outputfile,"r")
    if file then
        --Read output file and store all lines not part of inputtable and temptable
        for line in io.lines(outputfile) do
            if not string.match(line,"^"..inputtable[1][1]..",") then
                temptable[(#temptable+1)] = line
                --print(temptable[#temptable])
            end
        end
    end 
    -- Start writing to output file, write temptable and then inputtable
    file = io.open(outputfile,"w")
    file:write("MaryTTS Manager interface file created/updated on ",os.date("%x, %H:%M:%S"),"\n")
    file:write("\n")
    for j=3,#temptable do
        file:write(temptable[j].."\n")
    end
    for j=2,#inputtable do
        file:write(inputtable[1][1]..",")
        for k=1,#inputtable[j] do
            if type(inputtable[j][k]) == "string" or type(inputtable[j][k]) == "number" then file:write(inputtable[j][k]..MTTSM_SaveFileDelimiter..type(inputtable[j][k])) end
            if type(inputtable[j][k]) == "table" then
                file:write("{")
                for l=1,#inputtable[j][k] do
                    file:write(inputtable[j][k][l]..MTTSM_SaveFileDelimiter..type(inputtable[j][k][l]))
                    if l < #inputtable[j][k] then file:write(";") end
                end
                file:write("}")
            end
            if k < #inputtable[j] then file:write(",") else file:write("\n") end
        end    
    end
    if file:seek("end") > 0 then 
        if log == "log" then MTTSM_Notification("FILE WRITE SUCCESS: "..outputfile,"Success","log") else MTTSM_Notification("FILE WRITE SUCCESS: "..outputfile,"Success") end
    else 
        if log == "log" then MTTSM_Notification("FILE WRITE ERROR: "..outputfile,"Error","log") else MTTSM_Notification("FILE WRITE ERROR: "..outputfile,"Error") end 
    end
    file:close()
end
--[[ Check Autosave status ]]
function MTTSM_CheckAutosave(inputtable,outputfile,log)
    if MTTSM_SettingsValGet("AutoSave") == 1 then
        if log == "log" then MTTSM_FileWrite(inputtable,outputfile,log)
        else MTTSM_FileWrite(inputtable,outputfile) end
    end
end
--[[ Splits a line at the designated delimiter, returns a table ]]
function MTTSM_SplitString(input,delim)
    local output = {}
	--print("Line splitting in: "..input)
	for i in string.gmatch(input,delim) do table.insert(output,i) end
	--print("Line splitting out: "..table.concat(output,",",1,#output))
	return output
end

--[[ Merges subtables for printing ]]
function MTTSM_TableMergeAndPrint(intable)
    local tmp = {}
    for i=1,#intable do
        if type(intable[i]) ~= "table" then tmp[i] = tostring(intable[i]) end
        if type(intable[i]) == "table" then tmp[i] = tostring("{"..table.concat(intable[i],",").."}") end
    end
    return tostring(table.concat(tmp,","))
end

--[[ Read file ]]
function MTTSM_FileRead(inputfile,outputtable)
    -- Start reading input file
    local file = io.open(inputfile,"r")
    if file then
        MTTSM_Log_Write("FILE INIT READ: "..inputfile)
        local i = 0
        for line in file:lines() do
            -- Find lines matching first subtable of output table
            if string.match(line,"^"..outputtable[1][1]..",") then
                local temptable = {}
                local splitline = MTTSM_SplitString(line,"([^,]+)")
                for j=2,#splitline do
                   if string.match(splitline[j],"{") then -- Handle tables
                       local tempsubtable = {}
                       local splittable = MTTSM_SplitString(splitline[j],"{(.*)}") -- Strip brackets
                       local splittableelements = MTTSM_SplitString(splittable[1],"([^;]+)") -- Split at ;
                       for k=1,#splittableelements do
                          local substringtemp = MTTSM_SplitString(splittableelements[k],"([^"..MTTSM_SaveFileDelimiter.."]+)")
                          if substringtemp[2] == "string" then tempsubtable[k] = tostring(substringtemp[1]) end
                          if substringtemp[2] == "number" then tempsubtable[k] = tonumber(substringtemp[1]) end
                       end
                       temptable[j-1] = tempsubtable
                       --print("Table: "..table.concat(temptable[j-1],"-"))
                   else -- Handle regular variables
                        local substringtemp = MTTSM_SplitString(splitline[j],"([^"..MTTSM_SaveFileDelimiter.."]+)")
                        if substringtemp[2] == "string" then substringtemp[1] = tostring(substringtemp[1]) end
                        if substringtemp[2] == "number" then substringtemp[1] = tonumber(substringtemp[1]) end
                        temptable[j-1] = substringtemp[1]
                   end
                end
                --print(MTTSM_TableMergeAndPrint(temptable))
                -- Find matching line in output table
                for m=2,#outputtable do
                    -- Handle string at index 1
                    if type(temptable[1]) ~= "table" and temptable[1] == outputtable[m][1] then
                        --print("Old: "..MTTSM_TableMergeAndPrint(outputtable[m]))
                        for n=2,#temptable do
                            outputtable[m][n] = temptable[n]
                        end
                        --print("New: "..MTTSM_TableMergeAndPrint(outputtable[m]))
                    elseif type(temptable[1]) == "table" and temptable[1][1] == outputtable[m][1][1] then
                        --print("Old: "..MTTSM_TableMergeAndPrint(outputtable[m]))
                        for n=1,#temptable do
                            outputtable[m][n] = temptable[n]
                        end
                        --print("New: "..MTTSM_TableMergeAndPrint(outputtable[m]))
                    end
                end
            end
            i = i+1
        end
        file:close()
        if i ~= nil and i > 0 then MTTSM_Notification("FILE READ SUCCESS: "..inputfile,"Success","log") else MTTSM_Notification("FILE READ ERROR: "..inputfile,"Error","log") end   
    else
        MTTSM_Notification("FILE NOT FOUND: "..inputfile,"Error","log")
		--MTTSM_Check_AutoLoad = false
	end
end
--[[ Page initialization ]]
local function MTTSM_Page_Init()
    if MTTSM_PageInitStatus == 0 then MTTSM_Refresh_PageDB(MTTSM_PageTitle) MTTSM_PageInitStatus = 1 end
end
--[[ Displays a tooltip ]]
function MTTSM_ItemTooltip(string)
    if imgui.IsItemActive() or imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(imgui.GetFontSize() * 30)
        imgui.TextUnformatted(string)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end
--[[ Converter for various units ]]
function MTTSM_UnitConverter(invalue,inunit,outunit)
	local outvalue = 0
    -- Length
	if inunit == "nm" and outunit == "km" then outvalue = invalue * 1.85200 end 	-- Nautical miles to kilometres
	if inunit == "m" and outunit == "ft" then outvalue = invalue * 3.28084 end		-- Metre to foot
    if inunit == "m" and outunit == "in" then outvalue = invalue * 39.3701 end      -- Metre to inch
    if inunit == "m" and outunit == "cm" then outvalue = invalue * 100 end		    -- Metre to centimetre
    if inunit == "cm" and outunit == "ft" then outvalue = invalue / 30.48 end       -- Centimetre to foot
    if inunit == "cm" and outunit == "in" then outvalue = invalue / 2.54 end        -- Centimetre to inch
    if inunit == "cm" and outunit == "m" then outvalue = invalue / 100 end		    -- Centimetre to metre
    if inunit == "ft" and outunit == "m" then outvalue = invalue / 3.28084 end		-- Foot to metre
    if inunit == "ft" and outunit == "cm" then outvalue = invalue * 30.48 end		-- Foot to centimetre
	if inunit == "ft" and outunit == "in" then outvalue = invalue * 12 end		    -- Foot to inch
	if inunit == "in" and outunit == "m" then outvalue = invalue / 39.3701 end	    -- Inch to metre
	if inunit == "in" and outunit == "cm" then outvalue = invalue * 2.54 end	    -- Inch to centimetre
	if inunit == "in" and outunit == "ft" then outvalue = invalue / 12 end	        -- Inch to foot
    -- Mass
	if inunit == "kg" and outunit == "lbs" then outvalue = invalue * 2.20462 end	-- Kilograms to pounds mass
	if inunit == "lbs" and outunit == "kg" then outvalue = invalue / 2.20462 end	-- Pounds mass to kilograms
    -- Velocity
	if inunit == "kts" and outunit == "kph" then outvalue = invalue * 1.85200 end	-- Knots to kilometres per hour
	if inunit == "kts" and outunit == "mph" then outvalue = invalue * 1.15078 end	-- Knots to miles per hour
    -- No change
    if inunit == outunit then outvalue = invalue end
	return outvalue
end
--[[ Switches a unit ]]
function MTTSM_SwitchUnit_Single(inputtable,target,subtabindex,index,prop)
    if prop == "mass" then
        if MTTSM_SubTableValGet(inputtable,target,subtabindex,index) == "lbs" then MTTSM_SubTableValSet(inputtable,target,subtabindex,index,"kg")
        elseif MTTSM_SubTableValGet(inputtable,target,subtabindex,index) == "kg" then MTTSM_SubTableValSet(inputtable,target,subtabindex,index,"lbs") end
    end
    if prop == "length" then
        if MTTSM_SubTableValGet(inputtable,target,subtabindex,index) == "in" then MTTSM_SubTableValSet(inputtable,target,subtabindex,index,"ft")
        elseif MTTSM_SubTableValGet(inputtable,target,subtabindex,index) == "ft" then MTTSM_SubTableValSet(inputtable,target,subtabindex,index,"m")
        elseif MTTSM_SubTableValGet(inputtable,target,subtabindex,index) == "m" then MTTSM_SubTableValSet(inputtable,target,subtabindex,index,"cm")
        elseif MTTSM_SubTableValGet(inputtable,target,subtabindex,index) == "cm" then MTTSM_SubTableValSet(inputtable,target,subtabindex,index,"in")
        end
    end
end
--[[ Page initialization ]]
local function MTTSM_Page_Init()
    if MTTSM_PageInitStatus == 0 then MTTSM_Refresh_PageDB(MTTSM_PageTitle) MTTSM_PageInitStatus = 1 end
end
--[[ 

IMGUI WINDOW ELEMENT

]]
function MTTSM_Win_FileIODebug()
    --[[ Check page init status ]]
    MTTSM_Page_Init()
    --[[ Button ]]
    if MTTSM_SettingsValGet("Window_Page") == MTTSM_PageNumGet("Main Menu") then
        --imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),19)
        if imgui.Button(MTTSM_PageTitle,(MTTSM_SettingsValGet("Window_W")-30),20) then 
            MTTSM_SettingsValSet("Window_Page",MTTSM_PageNumGet(MTTSM_PageTitle))
            MTTSM_Settings_CheckAutosave() 
        end
    end
    --[[ Page ]]
    if MTTSM_SettingsValGet("Window_Page") == MTTSM_PageNumGet(MTTSM_PageTitle) then
        --[[ Set the page title ]]
        float_wnd_set_title(MTTSM_Window, MTTSM_ScriptName.." ("..MTTSM_PageTitle..")")
        --[[ "Main Menu" button ]]
        MTTSM_Win_Button_Back("Main Menu")
        --[[ File content ]]
        for i=1,#TestArray do
            imgui.TextUnformatted(MTTSM_TableMergeAndPrint(TestArray[i]))
        end
        imgui.Dummy((MTTSM_SettingsValGet("Window_W")-30),10)
        --[[ "Read" button ]]
        if imgui.Button("Read File",(MTTSM_SettingsValGet("Window_W")-30),20) then MTTSM_FileRead(TargetFile,TestArray) end
        --[[ "Write" button ]]
        if imgui.Button("Write File",(MTTSM_SettingsValGet("Window_W")-30),20) then MTTSM_FileWrite(TestArray,TargetFile) end
    --[[ End page ]]    
    end
end
