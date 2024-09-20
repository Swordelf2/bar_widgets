local util = VFS.Include("luaui/widgets/mod/util.lua")

local cFramesToWait = 1
local cConfigFile = "LuaUI/config/my_camera_config.lua"

local camDistFromGround = 100 -- some default

local closeShortDist = 700

-- Default values, if config is empty
local config = {
    short = 1750,
    medium = 4000,
    long = 8000,
    longx = nil,
    longz = nil
}

-- speedups
local spGetCameraState = Spring.GetCameraState
local spSetCameraState = Spring.SetCameraState

function widget:GetInfo()
    return {
        name = "My Camera",
        desc = "Adds my_camera* actions to zoom in and zoom out",
        author = "Swordelf",
        date = "Jan 20, 2024",
        license = "don't care",
        layer = 1,
        enabled = true
    }
end

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
    table.save(config, cConfigFile, "-- My Camera Widget distance configuration")
    local logStr = "Saved " .. widget:GetInfo().name .. " to " .. cConfigFile
    Spring.Log("my_camera", LOG.INFO, logStr)
end


-- Zooming In is different from Zooming out in that we need to
-- also center the camera on the cursor.
local function cameraZoomIn(dist, camState)
    local x, _, z = util.MouseWorldCoords()
    if x == nil then
        Spring.Echo("Mouse is off map")
    elseif dist < camState.dist then
        camState.px = x
        camState.pz = z
        -- local coeff = (camState.dist - dist) / camState.dist
        -- camState.px = camState.px + (x - camState.px) * coeff
        -- camState.pz = camState.pz + (z - camState.pz) * coeff
    end
    camState.dist = dist
    spSetCameraState(camState, 1)
end

local function cameraZoomOut(dist, camState, is_long)
    camState.dist = dist
    if is_long and config.longx ~= nil and config.longz ~= nil then
        camState.px = config.longx
        camState.pz = config.longz
    end
    spSetCameraState(camState, 1)
end

local function actionCameraZoomOut()
    local camState = spGetCameraState()
    if camState.dist < config.long - 150 then
        cameraZoomOut(config.long, camState, true)
    else
        cameraZoomIn(config.medium, camState)
    end
end

local function actionCameraZoomIn()
    local camState = spGetCameraState()
    if camState.dist > config.short then
        cameraZoomIn(config.short, camState)
    else
        cameraZoomOut(config.medium, camState)
    end
end

local function actionCameraSaveDist(_, _, args, _, isRepeat)
    if isRepeat then
        return
    end
    local mode = args[1]
    if config[mode] == nil then
        Spring.Echo("Invalid MyCamera mode: ", mode)
        return
    end

    local camState = spGetCameraState()
    config[mode] = camState.dist
    if mode == "long" then
        config.longx = camState.px
        config.longz = camState.pz
    end

    saveConfig({
        config = config
    })
    Spring.Echo("Saved cam config for mode '", mode, "' to ", camState.dist)
end

local function actionCameraZoomInClose()
    local camState = spGetCameraState()
    cameraZoomIn(closeShortDist, camState)
end

function widget:Initialize()
    config = readConfig().config or config
    widgetHandler:AddAction("my_camera_zoom_out", actionCameraZoomOut, nil, "p")
    widgetHandler:AddAction("my_camera_zoom_in", actionCameraZoomIn, nil, "p")
    widgetHandler:AddAction("my_camera_zoom_in_close", actionCameraZoomInClose, nil, "p")
    widgetHandler:AddAction("my_camera_save_dist", actionCameraSaveDist, nil, "p")
end

-- LOCAL STUFF END

-- local function setCamDistAction()
--     if spGetCameraState().name ~= "ov" then
--         return
--     end
--     framesPassed = 0
-- end

-- local function setCameraDistance()
--     local camState = spGetCameraState()
--     camState.dist = camDistFromGround
--     Spring.SetCameraState(camState, 1)
-- end

-- function widget:Update()
--     if framesPassed == nil then
--         return
--     end
--     framesPassed = framesPassed + 1
--     if framesPassed >= cFramesToWait then
--         framesPassed = nil
--         setCameraDistance()
--     end
-- end

-- local function saveCamDistAction()
--     local camState = spGetCameraState()
--     if camState.name ~= "spring" then
--         Spring.Log("some_section", LOG.WARNING, "Not in Spring camera")
--         return
--     end
--     camDistFromGround = camState.dist
--     saveConfig({
--         dist = camState.dist
--     })
-- end

-- local function toggleAndFocusCamAction(_, _, args, _, _)
--     if spGetCameraState().name == "ov" then
--         Spring.SendCommands({"toggleoverview"})
--     end
--     Spring.Echo(args)
--     if #args ~= 1 then
--         return
--     end
-- end
