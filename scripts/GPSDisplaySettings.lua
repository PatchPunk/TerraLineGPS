-- TerraLine GPS: line visibility, ground height and optical thickness per savegame.
-- New XML attributes use unique names; old experimental height/width are ignored.
GPSDisplaySettings={loadedPath=nil,dirty=false,defaultStrokes=1,
    defaultDurationSeconds=0,defaultHeightMeters=0.10,defaultThicknessMeters=0.00,
    defaultPlowMode=true,defaultPlowOverlapPercent=0}
local M=GPSDisplaySettings
local function clampStrokes(n)
    if type(n)~="number" or n~=n then return M.defaultStrokes end
    return math.max(1,math.min(3,math.floor(n+0.5)))
end
local function clampDuration(n)
    -- 0 means IMMER; fixed choices avoid accidental free-form timings.
    if n==2 or n==5 or n==10 then return n end
    return M.defaultDurationSeconds
end
local function clampHeight(n)
    if type(n)~="number" or n~=n then return M.defaultHeightMeters end
    return math.floor(math.max(0.10,math.min(4.0,n))*100+0.5)/100
end
local function clampThickness(n)
    if type(n)~="number" or n~=n then return M.defaultThicknessMeters end
    return math.floor(math.max(0,math.min(0.30,n))*100+0.5)/100
end
-- Free 1-percent steps on either side of zero. Protect the geometry from
-- extremely narrow or wide lanes, while allowing ordinary plough settings.
local function clampOverlap(percent)
    if type(percent)~="number" or percent~=percent then return M.defaultPlowOverlapPercent end
    return math.max(-50,math.min(50,math.floor(percent+0.5)))
end
local function getPath()
    local info=g_currentMission and g_currentMission.missionInfo
    local folder=info and info.savegameDirectory
    if type(folder)~="string" or folder=="" then return nil end
    return folder.."/terralineDisplay.xml"
end
function M.reset()
    M.loadedPath=nil
    M.dirty=false
    GPSConfig.lineStrokes=M.defaultStrokes
    GPSConfig.lineDurationSeconds=M.defaultDurationSeconds
    GPSConfig.lineHeightMeters=M.defaultHeightMeters
    GPSConfig.lineThicknessMeters=M.defaultThicknessMeters
    GPSConfig.plowModeEnabled=M.defaultPlowMode
    GPSConfig.plowOverlapPercent=M.defaultPlowOverlapPercent
end
function M.ensureLoaded()
    local path=getPath()
    if not path or path==M.loadedPath then return end
    M.loadedPath=path
    GPSConfig.lineStrokes=M.defaultStrokes
    GPSConfig.lineDurationSeconds=M.defaultDurationSeconds
    GPSConfig.lineHeightMeters=M.defaultHeightMeters
    GPSConfig.lineThicknessMeters=M.defaultThicknessMeters
    GPSConfig.plowModeEnabled=M.defaultPlowMode
    GPSConfig.plowOverlapPercent=M.defaultPlowOverlapPercent
    if type(fileExists)~="function" or not fileExists(path) or type(loadXMLFile)~="function" then return end
    -- Failures in the GIANTS XML API must reach the game log rather than
    -- being swallowed by a protected call. The surrounding existence checks
    -- still handle savegames without an existing display configuration.
    local xml=loadXMLFile("TerraLineDisplay",path)
    if not xml or xml==0 then return end
    local n,duration,height,thickness,mode,overlap,overlapSchema
    if type(getXMLInt)=="function" then
        n=getXMLInt(xml,"terralineDisplay#strokes")
        duration=getXMLInt(xml,"terralineDisplay#lineDurationSeconds")
        mode=getXMLInt(xml,"terralineDisplay#plowMode")
        overlap=getXMLInt(xml,"terralineDisplay#plowOverlapPercent")
        overlapSchema=getXMLInt(xml,"terralineDisplay#plowOverlapSchema")
    end
    if type(getXMLFloat)=="function" then
        height=getXMLFloat(xml,"terralineDisplay#lineHeightMeters")
        thickness=getXMLFloat(xml,"terralineDisplay#lineThicknessMeters")
    end
    if type(delete)=="function" then delete(xml) end
    GPSConfig.lineStrokes=clampStrokes(n)
    GPSConfig.lineDurationSeconds=clampDuration(duration)
    GPSConfig.lineHeightMeters=clampHeight(height)
    GPSConfig.lineThicknessMeters=clampThickness(thickness)
    GPSConfig.plowModeEnabled=(mode==nil) and M.defaultPlowMode or mode==1
    -- Old testbuilds stored only -3/-4/-5 and had no schema marker.
    -- On first opening after this update they start at the new neutral 0%.
    -- Values subsequently chosen in the new UI are preserved.
    GPSConfig.plowOverlapPercent=(overlapSchema==2) and clampOverlap(overlap) or M.defaultPlowOverlapPercent
end
function M.save()
    local path=getPath()
    if not path or type(createXMLFile)~="function" or type(setXMLInt)~="function" or
            type(setXMLFloat)~="function" or type(saveXMLFile)~="function" then
        return false,"Spielstand/XML nicht verfuegbar"
    end
    -- Make XML failures visible to the engine log. A missing XML handle is
    -- still reported through the existing menu result contract.
    local xml=createXMLFile("TerraLineDisplay",path,"terralineDisplay")
    if not xml or xml==0 then
        if GPSLogger and GPSLogger.info then
            GPSLogger.info("Linien-Optik: Speicherfehler (XML konnte nicht erstellt werden)")
        end
        return false,"Linien-Optik konnte nicht gespeichert werden"
    end
    setXMLInt(xml,"terralineDisplay#strokes",clampStrokes(GPSConfig.lineStrokes))
    setXMLInt(xml,"terralineDisplay#lineDurationSeconds",clampDuration(GPSConfig.lineDurationSeconds))
    setXMLFloat(xml,"terralineDisplay#lineHeightMeters",clampHeight(GPSConfig.lineHeightMeters))
    setXMLFloat(xml,"terralineDisplay#lineThicknessMeters",clampThickness(GPSConfig.lineThicknessMeters))
    setXMLInt(xml,"terralineDisplay#plowMode",GPSConfig.plowModeEnabled and 1 or 0)
    setXMLInt(xml,"terralineDisplay#plowOverlapPercent",clampOverlap(GPSConfig.plowOverlapPercent))
    setXMLInt(xml,"terralineDisplay#plowOverlapSchema",2)
    saveXMLFile(xml)
    if type(delete)=="function" then delete(xml) end
    M.dirty=false
    return true,"Linien-Optik gespeichert"
end
function M.setStrokes(n)
    M.ensureLoaded()
    GPSConfig.lineStrokes=clampStrokes(n)
    M.dirty=true
    return M.save()
end
function M.setHeightMeters(meters)
    M.ensureLoaded()
    GPSConfig.lineHeightMeters=clampHeight(meters)
    M.dirty=true
    return M.save()
end
function M.setThicknessMeters(meters)
    M.ensureLoaded()
    GPSConfig.lineThicknessMeters=clampThickness(meters)
    M.dirty=true
    return M.save()
end
function M.setDurationSeconds(seconds)
    M.ensureLoaded()
    GPSConfig.lineDurationSeconds=clampDuration(seconds)
    M.dirty=true
    local ok,msg=M.save()
    -- If the user changes the duration while steering is active, allow an
    -- immediate fresh preview rather than keeping an already expired timer.
    if GPSFieldTest and GPSSteeringController and GPSSteeringController.enabled then
        GPSFieldTest.assistLinesActivatedAtMs=GPSFieldTest.totalMs or 0
    end
    return ok,msg
end
function M.setPlowMode(enabled)
    M.ensureLoaded()
    GPSConfig.plowModeEnabled=(enabled==true)
    M.dirty=true
    return M.save()
end
function M.setPlowOverlapPercent(percent)
    M.ensureLoaded()
    GPSConfig.plowOverlapPercent=clampOverlap(percent)
    M.dirty=true
    return M.save()
end
function M.restoreDefaults()
    M.ensureLoaded()
    GPSConfig.lineStrokes=M.defaultStrokes
    GPSConfig.lineDurationSeconds=M.defaultDurationSeconds
    GPSConfig.lineHeightMeters=M.defaultHeightMeters
    GPSConfig.lineThicknessMeters=M.defaultThicknessMeters
    M.dirty=true
    local ok,msg=M.save()
    if GPSFieldTest and GPSSteeringController and GPSSteeringController.enabled then
        GPSFieldTest.assistLinesActivatedAtMs=GPSFieldTest.totalMs or 0
    end
    return ok,msg
end
