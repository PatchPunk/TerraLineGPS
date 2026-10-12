-- TerraLine GPS: stroke count and temporary guidance-line visibility, per savegame.
-- Old terralineDisplay.xml height/width settings are intentionally ignored.
-- Line renderer uses a fixed ground height and three selectable stroke counts.
GPSDisplaySettings={loadedPath=nil,dirty=false,defaultStrokes=1,defaultDurationSeconds=0}
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
end
function M.ensureLoaded()
    local path=getPath()
    if not path or path==M.loadedPath then return end
    M.loadedPath=path
    GPSConfig.lineStrokes=M.defaultStrokes
    GPSConfig.lineDurationSeconds=M.defaultDurationSeconds
    if type(fileExists)~="function" or not fileExists(path) or type(loadXMLFile)~="function" then return end
    local ok,xml=pcall(loadXMLFile,"TerraLineDisplay",path)
    if not ok or not xml or xml==0 then return end
    local readOk,n,duration=pcall(function()
        if type(getXMLInt)=="function" then
            return getXMLInt(xml,"terralineDisplay#strokes"),
                   getXMLInt(xml,"terralineDisplay#lineDurationSeconds")
        end
        return nil,nil
    end)
    if type(delete)=="function" then pcall(delete,xml) end
    if readOk then
        GPSConfig.lineStrokes=clampStrokes(n)
        GPSConfig.lineDurationSeconds=clampDuration(duration)
    end
end
function M.save()
    local path=getPath()
    if not path or type(createXMLFile)~="function" or type(setXMLInt)~="function" then
        return false,"Spielstand/XML nicht verfuegbar"
    end
    local ok,err=pcall(function()
        local xml=createXMLFile("TerraLineDisplay",path,"terralineDisplay")
        if not xml or xml==0 then error("XML konnte nicht erstellt werden") end
        setXMLInt(xml,"terralineDisplay#strokes",clampStrokes(GPSConfig.lineStrokes))
        setXMLInt(xml,"terralineDisplay#lineDurationSeconds",clampDuration(GPSConfig.lineDurationSeconds))
        saveXMLFile(xml)
        if type(delete)=="function" then delete(xml) end
    end)
    if not ok then
        if GPSLogger and GPSLogger.info then GPSLogger.info("Linien-Optik: Speicherfehler "..tostring(err)) end
        return false,"Linien-Optik konnte nicht gespeichert werden"
    end
    M.dirty=false
    return true,"Linien-Optik gespeichert"
end
function M.setStrokes(n)
    M.ensureLoaded()
    GPSConfig.lineStrokes=clampStrokes(n)
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
function M.restoreDefaults()
    M.ensureLoaded()
    GPSConfig.lineStrokes=M.defaultStrokes
    GPSConfig.lineDurationSeconds=M.defaultDurationSeconds
    M.dirty=true
    local ok,msg=M.save()
    if GPSFieldTest and GPSSteeringController and GPSSteeringController.enabled then
        GPSFieldTest.assistLinesActivatedAtMs=GPSFieldTest.totalMs or 0
    end
    return ok,msg
end
