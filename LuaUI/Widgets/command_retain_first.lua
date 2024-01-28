local util = VFS.Include("luaui/widgets/mod/util.lua")

local cActionName = "command_retain_first"

-- Speedups
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitCommands = Spring.GetUnitCommands
local spGiveOrderToUnit = Spring.GiveOrderToUnit

function widget:GetInfo()
    return {
        name = "Command Retain First",
        desc = "Adds action " .. cActionName .. " which cancels all commands except the current one in the queue",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 28, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

local function retainFirst(unitID)
    local commands = spGetUnitCommands(unitID, -1)
    for commandIdx, command in ipairs(commands) do
        if commandIdx ~= 1 then
            spGiveOrderToUnit(unitID, CMD.REMOVE, {command.tag}, {})
        end
    end
end

local function commandRetainFirstAction()
    local units = spGetSelectedUnits()
    if units == nil then
        return
    end

    for _, unitID in ipairs(units) do
        retainFirst(unitID)
    end
end

function widget:Initialize()
    widgetHandler:AddAction(cActionName, commandRetainFirstAction, nil, "p")
end

