-- Resolves the player-controlled vehicle (Courseplay's approach: g_localPlayer:getCurrentVehicle()).
-- Never modifies vehicles. Diagnostics intentionally throttled in GPSFieldTest.
GPSVehicleDetector = {}

local function safeCall(object, methodName)
    if object == nil then return nil end
    local okMethod, fn = pcall(function() return object[methodName] end)
    if not okMethod or type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, object)
    if ok and result ~= nil and result ~= false then return result end
    return nil
end

function GPSVehicleDetector.getCurrentVehicle()
    local localPlayer = g_localPlayer
    local vehicle = safeCall(localPlayer, "getCurrentVehicle")
    if vehicle ~= nil then return vehicle, "g_localPlayer:getCurrentVehicle" end

    -- Mission fallbacks for contexts with different player exposure.
    local mission = g_currentMission
    if mission == nil then return nil, "g_currentMission=nil" end
    local player = mission.player
    vehicle = safeCall(player, "getCurrentVehicle")
    if vehicle ~= nil then return vehicle, "mission.player:getCurrentVehicle" end
    vehicle = safeCall(mission, "getControlledVehicle")
    if vehicle ~= nil then return vehicle, "mission:getControlledVehicle" end
    if mission.controlledVehicle ~= nil then return mission.controlledVehicle, "mission.controlledVehicle" end
    if player ~= nil then
        if player.currentVehicle ~= nil then return player.currentVehicle, "mission.player.currentVehicle" end
        if player.vehicle ~= nil then return player.vehicle, "mission.player.vehicle" end
    end
    return nil, string.format("localPlayer=%s missionPlayer=%s controlled=%s",
        tostring(localPlayer ~= nil), tostring(player ~= nil), tostring(mission.controlledVehicle ~= nil))
end

function GPSVehicleDetector.getPositionNode(vehicle)
    if vehicle == nil then return nil end
    if vehicle.rootNode ~= nil then return vehicle.rootNode end
    if vehicle.components and vehicle.components[1] then return vehicle.components[1].node end
    return nil
end

function GPSVehicleDetector.getDisplayName(vehicle)
    if vehicle == nil then return "Kein Fahrzeug" end
    local name = safeCall(vehicle, "getName")
    if type(name) == "string" and name ~= "" then return name end
    local raw = vehicle.configFileName
    if type(raw) == "string" then return raw:match("([^/\\]+)%.xml$") or "Fahrzeug" end
    return "Fahrzeug"
end
