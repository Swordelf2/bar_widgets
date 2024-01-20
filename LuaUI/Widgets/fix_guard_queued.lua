-- Speedups
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue

function widget:GetInfo()
    return {
        name = "Fix Guard Queued",
        desc = "Fixes Double Guard canceling - remove Guard when guard is used",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 14, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
    if cmdID ~= CMD.GUARD then
        return false
    end

    local selectedUnits = Spring.GetSelectedUnits()
    if selectedUnits == nil then
        return false
    end
    for _, unitID in ipairs(selectedUnits) do
        local cmds = spGetCommandQueue(unitID, -1)
        if cmds then
            for k, unitCMD in ipairs(cmds) do
                if unitCMD.id == CMD.GUARD then
                    -- Spring.Echo(cmdParams)
                    spGiveOrderToUnit(unitID, CMD.REMOVE, {unitCMD.tag}, {})
                end
            end
        end
    end
    return false
end
