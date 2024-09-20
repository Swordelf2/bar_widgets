local util = VFS.Include("luaui/widgets/mod/util.lua")

local cCmdGuardOpts = {"shift"}

local spGetSelectedUnitsSorted = Spring.GetSelectedUnitsSorted
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetTeamUnitsSorted = Spring.GetTeamUnitsSorted
local spGetMyTeamID = Spring.GetMyTeamID
local spSelectUnit = Spring.SelectUnit
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local spGetCommandQueue = Spring.GetCommandQueue

local isBuilder = {}

local defIDPriority = {}
-- Elements are { id = number, priority = number, pos = { x = num, z = num } }
local myFactories = {}
local curCycleIdx = nil
local ignoreNextSelectionChanged = false
local myTeamID = spGetMyTeamID()

function widget:GetInfo()
    return {
        name = "Cycle Factories",
        desc = "Adds action to select next factory (descening in tier)",
        author = "Swordelf",
        version = "v0.1",
        date = "Jan 28, 2024",
        license = "I have no idea what licensing is, but you can take everything",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

local function addFactory(unitID, unitDefID, unitTeam)
    if unitTeam ~= myTeamID then
        return
    end
    
    -- This also checks if this is a factory
    local newPriority = defIDPriority[unitDefID]
    if newPriority == nil then
        return
    end

    local insertIdx = nil
    for idx, factory in ipairs(myFactories) do
        if newPriority < factory.priority then
            insertIdx = idx
            break
        end
    end
    if insertIdx == nil then
        insertIdx = #myFactories + 1
    end

    local posX, _, posZ = spGetUnitPosition(unitID)
    local newFactory = {
        id = unitID,
        priority = newPriority,
        pos = { x = posX, z = posZ },
    }

    table.insert(myFactories, insertIdx, newFactory)
end

local function removeFactory(unitID)
    local removeIdx = nil
    for idx, factory in ipairs(myFactories) do
        if factory.id == unitID then
            removeIdx = idx
        end
    end
    if removeIdx ~= nil then
        table.remove(myFactories, removeIdx)
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
    addFactory(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    removeFactory(unitID)
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
    if oldTeam == spGetMyTeamID() then
        removeFactory(unitID)
    else
        addFactory(unitID, unitDefID, newTeam)
    end
end

function widget:SelectionChanged(sel)
    if ignoreNextSelectionChanged then
        ignoreNextSelectionChanged = false
        return
    end
    curCycleIdx = nil
end

local function cycleFactoriesAction()
    if #myFactories == 0 then
        return
    end
    if curCycleIdx == nil or curCycleIdx == 1 then
        curCycleIdx = #myFactories
    else
        curCycleIdx = curCycleIdx - 1
    end
    ignoreNextSelectionChanged = true
    spSelectUnit(myFactories[curCycleIdx].id)
end

local function initializeMyFactories()
    myFactories = {}
    local myUnits = Spring.GetTeamUnits(myTeamID)
    for _, unitID in ipairs(myUnits) do
        local unitDefID = spGetUnitDefID(unitID)
        addFactory(unitID, unitDefID, myTeamID)
    end
end

local function initializeUnitDefPriorities()
    -- Tier 1 -> 3
    -- Type Amphibious, NavalHover, Hover, Seaplane, Ship, Air, Bot, Vehicle
    -- Faction arm -> cor
    local tier = 100
    local ty = 10
    local faction = 1
    return {
        ["armamsub"] = 0 * tier + 0 * ty + 0 * faction, -- amph
        ["armfhp"] = 0 * tier + 1 * ty + 0 * faction, -- naval hover
        ["armhp"] = 0 * tier + 2 * ty + 0 * faction, -- hover
        ["armplat"] = 0 * tier + 3 * ty + 0 * faction, -- seaplane
        ["armsy"] = 0 * tier + 4 * ty + 0 * faction, -- ship
        ["armasy"] = 1 * tier + 4 * ty + 0 * faction, -- ship t2
        ["armap"] = 0 * tier + 5 * ty + 0 * faction, -- air
        ["armaap"] = 1 * tier + 5 * ty + 0 * faction, -- air t2
        ["armlab"] = 0 * tier + 6 * ty + 0 * faction, -- bots
        ["armalab"] = 1 * tier + 6 * ty + 0 * faction, -- bots t2
        ["armvp"] = 0 * tier + 7 * ty + 0 * faction, -- veh 
        ["armavp"] = 1 * tier + 7 * ty + 0 * faction, -- veh t2
        ["armshltx"] = 2 * tier + 6 * ty + 0 * faction, -- gantry
        ["armshltxuw"] = 3 * tier + 6 * ty + 0 * faction, -- gantry underwater

        ["coramsub"] = 0 * tier + 0 * ty + 1 * faction, -- amph
        ["corfhp"] = 0 * tier + 1 * ty + 1 * faction, -- naval hover
        ["corhp"] = 0 * tier + 2 * ty + 1 * faction, -- hover
        ["corplat"] = 0 * tier + 3 * ty + 1 * faction, -- seaplane
        ["corsy"] = 0 * tier + 4 * ty + 1 * faction, -- ship
        ["corasy"] = 1 * tier + 4 * ty + 1 * faction, -- ship t2
        ["corap"] = 0 * tier + 5 * ty + 1 * faction, -- air
        ["coraap"] = 1 * tier + 5 * ty + 1 * faction, -- air t2
        ["corlab"] = 0 * tier + 6 * ty + 1 * faction, -- bots
        ["coralab"] = 1 * tier + 6 * ty + 1 * faction, -- bots t2
        ["corvp"] = 0 * tier + 7 * ty + 1 * faction, -- veh 
        ["coravp"] = 1 * tier + 7 * ty + 1 * faction, -- veh t2
        ["corshltx"] = 2 * tier + 6 * ty + 1 * faction, -- gantry
        ["corshltxuw"] = 3 * tier + 6 * ty + 1 * faction -- gantry underwater
    }
end

local function getMainFactory()
    if #myFactories == 0 then
        return nil
    else
        return myFactories[#myFactories]
    end
end

local function issueGuardFactory(units, factoryID)
    for _, unitID in ipairs(units) do
        util.RemoveCommand(unitID, function(cmd)
            return cmd.id == CMD.GUARD
        end)
    end
    spGiveOrderToUnitArray(units, CMD.GUARD, {factoryID}, cCmdGuardOpts)
end

local function issueGuardMainFactory(units)
    local mainFactory = getMainFactory()
    if mainFactory == nil then
        return
    end
    if units == nil then
        return
    end
    issueGuardFactory(units, mainFactory.id)
end

local function distSqr(pos1, pos2)
    local x_diff = pos1.x - pos2.x
    local z_diff = pos1.z - pos2.z
    return x_diff * x_diff + z_diff * z_diff
end

-- pos is { x = number, z = number }
local function findClosestFactoryTo(pos)
    if #myFactories == 0 then
        return nil
    end
    local minIdx = nil 
    local minDistSqr = nil
    for idx, factory in ipairs(myFactories) do
        local dSqr = distSqr(pos, factory.pos) 
        if minIdx == nil or dSqr < minDistSqr then
            minIdx = idx 
            minDistSqr = dSqr
        end
    end
    return myFactories[minIdx]
end

local function guardClosestFactoryAction()
    local units = spGetSelectedUnits()
    if units == nil or #units == 0 then
        return
    end
    
    local pivotPosX, _, pivotPosZ = util.MouseWorldCoords()
    -- fallback if mouse if offmap: use position of a random unit
    if pivotPosX == nil then
        for _, unitID in ipairs(units) do
            pivotPosX, _, pivotPosZ = spGetUnitPosition(unitID)
            break
        end
    end
    local pivotPos = { x = pivotPosX, z = pivotPosZ }

    local closestFactory = findClosestFactoryTo(pivotPos) 
    if closestFactory == nil then
        return
    end
    issueGuardFactory(units, closestFactory.id)
end

-- Check if `unitID` has a guard order onto on of the units in `unitsMap`.
local function isGuarding(unitID, unitsMap)
    local commandQueue = spGetCommandQueue(unitID, -1)
    if commandQueue == nil or #commandQueue == 0 then
        return false
    end
    local lastCommand = commandQueue[#commandQueue]
    if lastCommand.id ~= CMD.GUARD then
        return false
    end
    return unitsMap[lastCommand.params[1]]
end

-- releases builders guarding selected units - sets them to guard factory
local function releaseGuardsAction()
    local selectedUnits = spGetSelectedUnits()
    local selectedUnitsMap = {}
    for _, unitID in ipairs(selectedUnits) do
        selectedUnitsMap[unitID] = true
    end

    local guardingUnits = {}

    local allUnits = Spring.GetTeamUnits(myTeamID)
    for _, unit in ipairs(allUnits) do
        if isBuilder[spGetUnitDefID(unit)] then
            if isGuarding(unit, selectedUnitsMap) then
                table.insert(guardingUnits, unit)
            end
        end
    end

    issueGuardMainFactory(guardingUnits)
end

function widget:Initialize()
    myTeamID = spGetMyTeamID()
    local nameToPriority = initializeUnitDefPriorities()

    for unitDefID, unitDef in pairs(UnitDefs) do
        local priority = nameToPriority[unitDef.name]
        if priority ~= nil then
            defIDPriority[unitDefID] = priority
        end
        if unitDef.buildSpeed > 0 and unitDef.buildOptions[1] and not unitDef.isFactory then
            isBuilder[unitDefID] = true
        end
    end

    initializeMyFactories()

    widgetHandler:AddAction("cycle_factories", cycleFactoriesAction, nil, "p")
    -- Issues a shift guard command on my factory closest to mouse cursor 
    widgetHandler:AddAction("guard_closest_factory", guardClosestFactoryAction, nil, "p")
    
    -- Unused
    widgetHandler:AddAction("release_guards", releaseGuardsAction, nil, "p")
end
