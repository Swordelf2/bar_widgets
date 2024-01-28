local util = VFS.Include("luaui/widgets/mod/util.lua")

local cCmdGuardOpts = {"shift"}

local spGetSelectedUnitsSorted = Spring.GetSelectedUnitsSorted
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetMyTeamID = Spring.GetMyTeamID
local spSelectUnit = Spring.SelectUnit
local spGetUnitDefID = Spring.GetUnitDefID
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray

local defIDPriority = {}
local myFactoryIDs = {}
local myFactoryPriorities = {}
local curCycleIdx = nil
local ignoreNextSelectionChanged = false

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
    if unitTeam ~= spGetMyTeamID() then
        return
    end
    local newPriority = defIDPriority[unitDefID]
    if newPriority == nil then
        return
    end

    local insertIdx = nil
    for idx, priority in ipairs(myFactoryPriorities) do
        if newPriority < priority then
            insertIdx = idx
            break
        end
    end
    if insertIdx == nil then
        insertIdx = #myFactoryPriorities + 1
    end
    table.insert(myFactoryPriorities, insertIdx, newPriority)
    table.insert(myFactoryIDs, insertIdx, unitID)
end

local function removeFactory(unitID)
    local removeIdx = nil
    for idx, factoryID in ipairs(myFactoryIDs) do
        if factoryID == unitID then
            removeIdx = idx
        end
    end
    if removeIdx ~= nil then
        table.remove(myFactoryPriorities, removeIdx)
        table.remove(myFactoryIDs, removeIdx)
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
    if #myFactoryIDs == 0 then
        return
    end
    if curCycleIdx == nil or curCycleIdx == 1 then
        curCycleIdx = #myFactoryIDs
    else
        curCycleIdx = curCycleIdx - 1
    end
    ignoreNextSelectionChanged = true
    spSelectUnit(myFactoryIDs[curCycleIdx])
end

local function initializeMyFactories()
    myFactoryIDs = {}
    myFactoryPriorities = {}
    local myTeamID = spGetMyTeamID()
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
    if #myFactoryIDs == 0 then
        return nil
    else
        return myFactoryIDs[#myFactoryIDs]
    end
end

local function guardMainFactoryAction()
    local mainFactory = getMainFactory()
    if mainFactory == nil then
        return
    end
    local units = spGetSelectedUnits()
    if units == nil then
        return
    end
    for _, unitID in ipairs(units) do
        util.RemoveCommand(unitID, function(cmd)
            return cmd.id == CMD.GUARD
        end)
    end
    spGiveOrderToUnitArray(units, CMD.GUARD, {mainFactory}, cCmdGuardOpts)
end

function widget:Initialize()
    local nameToPriority = initializeUnitDefPriorities()

    for unitDefID, unitDef in pairs(UnitDefs) do
        local priority = nameToPriority[unitDef.name]
        if priority ~= nil then
            defIDPriority[unitDefID] = priority
        end
    end

    initializeMyFactories()

    widgetHandler:AddAction("cycle_factories", cycleFactoriesAction, nil, "p")
    widgetHandler:AddAction("guard_main_factory", guardMainFactoryAction, nil, "p")
end
