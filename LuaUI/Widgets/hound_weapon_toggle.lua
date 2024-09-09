local cActionName = "hound_weapon_toggle"

-- Speedups

local CMD_HOUND_WEAPON_TOGGLE = 37383

local houndDefId
for udid, ud in pairs(UnitDefs) do
	if ud.name == 'armfido' then
		houndDefId = udid
	end
end

function widget:GetInfo()
    return {
        name = "Hound Weapon Toggle command",
        desc = "Adds action " .. cActionName,
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 28, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

local function action(_, _, args)
    local state = args[1]
    if not (state == nil or state == "0" or state == "1") then
        return
    end

	local anyOrderGiven = false
    local selectedUnitsSorted = spGetSelectedUnitsSorted()
    for unitDefId, units in pairs(selectedUnits) do
        if unitDefId == houndDefId then
			anyOrderGiven = true
			for _, unit in pairs(units) do
				spGiveOrderToUnit(unit, CMD_HOUND_WEAPON_TOGGLE, { state }, 0)
            end
		end
    end
    return anyOrderGiven
end

function widget:Initialize()
    widgetHandler:AddAction(cActionName, action, nil, "p")
end

