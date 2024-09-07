local cFramesToWait = 1
local cConfigFile = "LuaUI/config/my_camera_dist_config.lua"

local camDistFromGround = 100 -- some default

-- Default values, if config is empty
local camDist = {
    short = 1750,
    medium = 3000,
    long = 5000
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

local function mouseWorldCoords()
    local mouseX, mouseY = Spring.GetMouseState()
    local desc, args = Spring.TraceScreenRay(mouseX, mouseY, true, false, --[[includeSky]] false)
    if nil == desc then
        return nil
    end -- off map
    local x = args[1]
    local y = args[2]
    local z = args[3]
    return x, y, z
end

-- Zooming In is different from Zooming out in that we need to
-- also center the camera on the cursor.
local function cameraZoomIn(dist, camState)
    local x, _, z = mouseWorldCoords()
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

local function cameraZoomOut(dist, camState)
    camState.dist = dist
    spSetCameraState(camState, 1)
end

local function actionCameraZoomOut()
    local camState = spGetCameraState()
    cameraZoomOut(camDist.long, camState)
end

local function actionCameraZoomIn()
    local camState = spGetCameraState()
    local curDist = camState.dist
    if curDist <= camDist.short - 50 then
        cameraZoomOut(camDist.short, camState)
    elseif curDist <= camDist.short + 50 then
        cameraZoomOut(camDist.medium, camState)
    elseif curDist <= camDist.medium + 50 then
        cameraZoomIn(camDist.short, camState)
    else
        cameraZoomIn(camDist.medium, camState)
    end
end

local function actionCameraSaveDist(_, _, args, _, isRepeat)
    if isRepeat then
        return
    end
    local mode = args[1]
    if camDist[mode] == nil then
        Spring.Echo("Invalid MyCamera mode: ", mode)
        return
    end
    local dist = spGetCameraState().dist
    Spring.Echo("Saving camDist for mode '", mode, "' to ", dist)
    camDist[mode] = dist
    saveConfig({
        camDist = camDist
    })
end

function widget:Initialize()
    camDist = readConfig().camDist or camDist
    widgetHandler:AddAction("my_camera_zoom_out", actionCameraZoomOut, nil, "p")
    widgetHandler:AddAction("my_camera_zoom_in", actionCameraZoomIn, nil, "p")
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
