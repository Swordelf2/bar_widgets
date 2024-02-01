local util = VFS.Include("luaui/widgets/mod/util.lua")

local cActionName = "guard_last_builder"
local cCmdOpts = {"shift"}

local isBuilder = {}
local lastBuilder = nil

local CMD_AREA_MEX = 10100

-- Speedups
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local spGetUnitDefID = Spring.GetUnitDefID
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue

function widget:GetInfo()
    return {
        name = "Guard Last Builder",
        desc = "Adds action to guard the last singly selected builder",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 20, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
    if not (cmdID < 0 or cmdID == CMD_AREA_MEX) then
        return false
    end
    local selectedUnits = spGetSelectedUnits()
    if not (selectedUnits and #selectedUnits == 1) then
        return false
    end
    local unitID = selectedUnits[1]
    if not isBuilder[spGetUnitDefID(unitID)] then
        return false
    end
    lastBuilder = unitID
    return false
end

local function action()
    if lastBuilder == nil then
        return
    end
    local units = Spring.GetSelectedUnits()
    if units == nil then
        return
    end
    -- Remove all guard commands and remove `lastBuilder` from `units`
    local oldUnits = units
    units = {}
    for _, unitID in ipairs(oldUnits) do
        if unitID ~= lastBuilder then
            util.RemoveCommand(unitID, function(cmd)
                return cmd.id == CMD.GUARD
            end)
            table.insert(units, unitID)
        end
    end
    -- Spring.GiveOrderToUnitArray(unitIDs, cmdID, params, cmdOpts)
    spGiveOrderToUnitArray(units, CMD.GUARD, {lastBuilder}, cCmdOpts)
end

function widget:Initialize()
    for unitDefID, unitDef in pairs(UnitDefs) do
        if unitDef.buildSpeed > 0 and unitDef.buildOptions[1] and not unitDef.isFactory then
            isBuilder[unitDefID] = true
        end
    end

    widgetHandler:AddAction(cActionName, action, nil, "p")
end
