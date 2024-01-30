local cActionName = "switch_trajectory"

-- Speedups
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray

function widget:GetInfo()
    return {
        name = "Command Switch Weapon",
        desc = "Adds action " .. cActionName .. " which switches weapon trajectory for units ",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 30, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

local function switchTrajectoryAction()
    local units = spGetSelectedUnits()
    if units == nil then
        return
    end
    local orderGiven = spGiveOrderToUnitArray(units, CMD.ONOFF, {0}, {})
end

function widget:Initialize()
    widgetHandler:AddAction(cActionName, switchTrajectoryAction, nil, "p")
end

