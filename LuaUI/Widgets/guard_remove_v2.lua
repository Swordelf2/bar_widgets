local util = VFS.Include("luaui/widgets/mod/util.lua")

-- Speedups
local spGetSelectedUnitsSorted = Spring.GetSelectedUnitsSorted
local spGetUnitDefID = Spring.GetUnitDefID

local isFactory = {}

function widget:GetInfo()
    return {
        name = "Guard Remove V2",
        desc = "Removes all Guard and Alt rec/rep/rez commands from queue when any shift command is issued",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 14, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

local function contains(array, value)
    for _, elem in ipairs(array) do
        if elem == value then
            return true
        end
    end
    return false 
end

local function cmdHasShift(cmdOpts)
    if cmdOpts.shift then
        return true
    end
    return contains(cmdOpts, "shift")
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
    if not cmdHasShift(cmdOpts) then
        return false
    end
    local selectedUnits = spGetSelectedUnitsSorted()
    if selectedUnits == nil then
        return false
    end
    for unitDefID, unitIDs in pairs(selectedUnits) do
        -- Don't remove guard for factories
        if not isFactory[unitDefID] then
            for _, unitID in ipairs(unitIDs) do
                util.RemoveCommand(unitID, function(cmd)
                    return cmd.id == CMD.GUARD or
                        (cmd.options.alt and (
                            cmd.id == CMD.REPAIR or
                            cmd.id == CMD.RESURRECT or
                            cmd.id == CMD.RECLAIM
                        ))
                end)
            end
        end
    end
    return false
end

function widget:Initialize()
    for unitDefID, unitDef in pairs(UnitDefs) do
        if unitDef.isFactory and #unitDef.buildOptions > 0 then
            isFactory[unitDefID] = true
        end
    end
end
