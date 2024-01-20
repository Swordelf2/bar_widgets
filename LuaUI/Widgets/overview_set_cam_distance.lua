local cFramesToWait = 1
local cConfigFile = "LuaUI/config/cam_dist_config.lua"

local camDistFromGround = 100 -- some default

function widget:GetInfo()
    return {
        name = "Overview Camera Set Fixed distance",
        desc = "When the overview closes, the camera sets a certain distance from ground",
        author = "Swordelf",
        date = "Jan 20, 2024",
        license = "don't care",
        layer = 1,
        enabled = true
    }
end

local framesPassed = -1

-- LOCAL STUFF
local function readConfig()
    local chunk, err = loadfile(cConfigFile)
    if chunk then
        local tmp = {}
        setfenv(chunk, tmp)
        return chunk()
    end
    return {}
end

local function saveConfig(config)
    table.save(config, cConfigFile, "-- Set Cam Distance Widget Configuration")
    local logStr = "Saved " .. widget:GetInfo().name .. " to " .. cConfigFile
    Spring.Log("some_section", LOG.INFO, logStr)
end

-- LOCAL STUFF END

local function setCamDistAction()
    framesPassed = 0
end

local function setCameraDistance()
    local camState = Spring.GetCameraState()
    camState.dist = camDistFromGround
    Spring.SetCameraState(camState, 1)
end

function widget:Update()
    if framesPassed == -1 then
        return
    end
    framesPassed = framesPassed + 1
    if framesPassed >= cFramesToWait then
        framesPassed = -1
        setCameraDistance()
    end
end

local function saveCamDistAction()
    local camState = Spring.GetCameraState()
    if camState.name ~= "spring" then
        Spring.Log("some_section", LOG.WARNING, "Not in Spring camera")
        return
    end
    camDistFromGround = camState.dist
    saveConfig({
        dist = camState.dist
    })
end

function widget:Initialize()
    widgetHandler:AddAction("set_cam_dist", setCamDistAction, nil, "p")
    widgetHandler:AddAction("save_cam_dist", saveCamDistAction, nil, "p")
    camDistFromGround = readConfig().dist or camDistFromGround
end

-- -- works only with single key binds
-- local function isCamKey(keyNum)
--     local pressedSymbol = Spring.GetKeySymbol(keyNum):upper()
--     for _, symbol in pairs(camKeys) do
--         if pressedSymbol == symbol then
--             return true
--         end
--     end
--     return false
-- end

-- local function isOverview()
--     return Spring.GetCameraState().name == "ov"
-- end

-- function widget:MouseWheel(up, value)
--     if isOverview() and up then
--         Spring.SendCommands({"toggleoverview"})
--         return true;
--     end

--     return false
-- end

-- function widget:KeyPress(key, modifier)
--     if not isCamKey(key) then
--         return
--     end
--     if isOverview() then
--         if prevCamState ~= nil then
--             Spring.SetCameraState(prevCamState, 1)
--         end
--     else
--         prevCamState = Spring.GetCameraState()
--     end
-- end

