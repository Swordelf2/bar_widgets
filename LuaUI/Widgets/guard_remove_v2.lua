local util = VFS.Include("luaui/widgets/mod/util.lua")

-- Speedups
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID = Spring.GetUnitDefID

local isFactory = {}

function widget:GetInfo()
    return {
        name = "Guard Remove V2",
        desc = "Removes all guard commands from queue when any command is issued",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 14, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
    local selectedUnits = spGetSelectedUnits()
    if selectedUnits == nil then
        return false
    end
    for _, unitID in ipairs(selectedUnits) do
        util.RemoveCommand(unitID, function(cmd)
            return cmd.id == CMD.GUARD
        end)
    end
    return false
end
