-- If true, the action additionally sets selected factories to Repeat Off.
local setRepeatOff = true

local cEmptyTbl = {}
local cDequeueCmdOpts = {"right"}

local isFactory = {}

function widget:GetInfo()
    return {
        name = "Factory Clear Queue",
        desc = "Adds action to clear factory queue except for the unit currently being built, also ignores stop command for factories",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 14, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

local function factoryClearQueueAction()
    -- Find all currently selected factories
    local selectedUnits = Spring.GetSelectedUnitsSorted()
    for unitDefID, unitIDs in pairs(selectedUnits) do
        if isFactory[unitDefID] then
            for _, factoryID in ipairs(unitIDs) do
                local cmds = Spring.GetFactoryCommands(factoryID, -1)
                local orderArray = {}
                if setRepeatOff then
                    table.insert(orderArray, {CMD.REPEAT, {0}, cEmptyTbl})
                end
                for num, cmd in ipairs(cmds) do
                    if num > 1 and cmd.id < 0 then
                        table.insert(orderArray, {cmd.id, cEmptyTbl, cDequeueCmdOpts})
                    end
                end
                if #orderArray > 0 then
                    Spring.GiveOrderArrayToUnit(factoryID, orderArray)
                end
            end
        end
    end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
    if cmdID ~= CMD.STOP then
        return false
    end

    local selectedUnits = Spring.GetSelectedUnitsSorted()
    local areAllFactories = true
    if selectedUnits == nil then
        return false
    end
    for unitDefID, unitIDs in pairs(selectedUnits) do
        if not isFactory[unitDefID] then
            return false
        end
    end
    return true
end

function widget:Initialize()
    for unitDefID, unitDef in pairs(UnitDefs) do
        if unitDef.isFactory and #unitDef.buildOptions > 0 then
            isFactory[unitDefID] = true
        end
    end

    widgetHandler:AddAction("factory_clear_queue", factoryClearQueueAction, nil, "p")
end
