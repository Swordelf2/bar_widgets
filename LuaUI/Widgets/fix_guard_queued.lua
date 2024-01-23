-- Speedups
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID = Spring.GetUnitDefID

local isFactory = {}

function widget:GetInfo()
    return {
        name = "Fix Guard Queued",
        desc = "Fixes Double Guard canceling - remove Guard when guard is used (unless on Factory)",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 14, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

local function RemoveCommand(unitID, shouldRemove)
    local cmds = spGetCommandQueue(unitID, -1)
    if cmds then
        for k, unitCMD in ipairs(cmds) do
            if shouldRemove(unitCMD) then
                Spring.Echo("removing command")
                spGiveOrderToUnit(unitID, CMD.REMOVE, {unitCMD.tag}, {})
            end
        end
    end
end

local function isUnitFactory(unitID)
    return isFactory[spGetUnitDefID(unitID)]
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
    if cmdID ~= CMD.GUARD then
        return false
    end

    local selectedUnits = spGetSelectedUnits()

    if #cmdParams >= 1 and isUnitFactory(cmdParams[1]) then
        Spring.Echo("In Factory")
        local factoryID = cmdParams[1]
        -- If issuing a guard factory, then only remove guards guarding this factory
        for _, unitID in ipairs(selectedUnits) do
            RemoveCommand(unitID, function(cmd)
                return cmd.id == CMD.GUARD and cmd.params[1] == factoryID
            end)
        end
        return false
    end

    if selectedUnits == nil then
        return false
    end
    for _, unitID in ipairs(selectedUnits) do
        RemoveCommand(unitID, function(cmd)
            return cmd.id == CMD.GUARD
        end)
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
