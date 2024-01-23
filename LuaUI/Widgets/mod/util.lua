local util = {}

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue

function util.RemoveCommand(unitID, shouldRemove)
    local cmds = spGetCommandQueue(unitID, -1)
    if cmds then
        for k, unitCMD in ipairs(cmds) do
            if shouldRemove(unitCMD) then
                spGiveOrderToUnit(unitID, CMD.REMOVE, {unitCMD.tag}, {})
            end
        end
    end
end

return util
