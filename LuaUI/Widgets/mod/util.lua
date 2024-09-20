local util = {}

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue

-- Removes all commands in the queue of the given unit based on prediate shouldRemove
-- which is a fn Command -> bool.
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

-- Returns x, y, z of mouse projected onto the world.
-- Nil of mouse is off the map.
function util.MouseWorldCoords()
    local mouseX, mouseY = Spring.GetMouseState()
    local desc, args = Spring.TraceScreenRay(mouseX, mouseY, true, false, --[[includeSky]] false)
    if nil == desc then
        return nil
    end -- off map
    local x = args[1]
    local y = args[2]
    local z = args[3]
    return x, y, z
end

return util
