-- TerraLine GPS: named independent A/B courses saved per savegame. No field detection.
-- Self-contained persistence; never changes SteeringController.lua.
GPSCourseManager={courses={},fieldNames={},loadedPath=nil,nextId=1,activeCourseName=nil,clientFarmId=nil,pollTime=0,observedFarmId=nil,pendingSave=nil,lastServerMessage=nil,cachedCoursesByFarm={},awaitingFarmSnapshot=nil}
local M=GPSCourseManager
local function log(s) if GPSLogger and GPSLogger.info then GPSLogger.info("TerraLine Kurse: "..tostring(s)) end end
local function directory()
    local mission=g_currentMission
    local info=mission and mission.missionInfo
    return info and info.savegameDirectory
end
local function filename()
    -- GIANTS replaces missionInfo.savegameDirectory with `tempsavegame`
    -- during a save. Our data must remain bound to the ORIGINAL save slot.
    if M.loadedPath~=nil then return M.loadedPath end
    local dir=directory()
    if type(dir)~="string" or #dir<3 then return nil end
    return dir.."/terralineGPS.xml"
end
local function cleanName(value)
    local name=tostring(value or ""):gsub("[%c]"," "):gsub("^%s+",""):gsub("%s+$","")
    return name:sub(1,48)
end
local function validNum(n)
    return type(n)=="number" and n==n and n>-1000000 and n<1000000
end
local function validFarm(id)
    return type(id)=="number" and id>=1 and id<=255 and id==math.floor(id)
        and not (FarmManager and id==FarmManager.SPECTATOR_FARM_ID)
end
local function remoteClient()
    return g_client~=nil and g_server==nil
end
function M.getFarmId()
    local mission=g_currentMission
    local id
    if mission and type(mission.getFarmId)=="function" then
        local ok,value=pcall(mission.getFarmId, mission)
        if ok then id=value end
    end
    if validFarm(id) then return id end
    -- A real MP spectator or not-yet-assigned client must not see farm data.
    -- In a singleplayer game without a farm API, preserve legacy Farm 1.
    if not remoteClient() and g_currentMission and g_currentMission.missionInfo
        and not (g_currentMission.missionInfo.isMultiplayer) then
        return 1
    end
    return nil
end
local function matchingCourses(farmId)
    local result={}
    if not validFarm(farmId) then return result end
    for _,c in ipairs(M.courses) do
        if c.farmId==farmId then result[#result+1]=c end
    end
    return result
end
function M.reset()
    M.courses={};M.fieldNames={};M.loadedPath=nil;M.nextId=1
    M.activeCourseName=nil;M.clientFarmId=nil;M.pollTime=0
    M.observedFarmId=nil;M.pendingSave=nil;M.lastServerMessage=nil
    M.cachedCoursesByFarm={};M.awaitingFarmSnapshot=nil
end
function M.ensureLoaded()
    if remoteClient() or M.loadedPath~=nil then return end
    -- Load exactly ONCE per map session. A savegameDirectory change on save
    -- must not reset the authoritative list to an empty tempsavegame snapshot.
    local path=filename()
    if not path then return end
    M.courses={};M.fieldNames={};M.nextId=1;M.loadedPath=path
    if type(fileExists)~="function" or not fileExists(path) or type(loadXMLFile)~="function" then
        log("SERVER-LOAD: keine Kursdatei unter "..tostring(path).." (neuer Stand oder Datei fehlt)")
        return
    end
    local ok,xml=pcall(loadXMLFile,"TerraLineCourses",path)
    if not ok or not xml or xml==0 then log("Kursdatei konnte nicht geladen werden");return end
    local success,err=pcall(function()
        for i=0,999 do
            local k=string.format("terraline.fields.field(%d)",i)
            local id=getXMLInt(xml,k.."#id")
            if id==nil then break end
            local name=cleanName(getXMLString(xml,k.."#name"))
            if name~="" then M.fieldNames[id]=name end
        end
        for i=0,1999 do
            local k=string.format("terraline.courses.course(%d)",i)
            local id=getXMLInt(xml,k.."#id")
            if id==nil then break end
            local farmId=getXMLInt(xml,k.."#farmId") or 1 -- Legacy SP data migrated to Farm 1.
            local fieldId=getXMLInt(xml,k.."#fieldId")
            local ax,az,bx,bz=getXMLFloat(xml,k.."#ax"),getXMLFloat(xml,k.."#az"),getXMLFloat(xml,k.."#bx"),getXMLFloat(xml,k.."#bz")
            if validFarm(farmId) and validNum(ax) and validNum(az) and validNum(bx) and validNum(bz) then
                M.courses[#M.courses+1]={id=id,farmId=farmId,fieldId=fieldId or 0,name=cleanName(getXMLString(xml,k.."#name")),
                    ax=ax,az=az,bx=bx,bz=bz,width=getXMLFloat(xml,k.."#width"),
                    offset=getXMLFloat(xml,k.."#offset") or 0}
                M.nextId=math.max(M.nextId,id+1)
            end
        end
    end)
    if type(delete)=="function" then pcall(delete,xml) end
    if not success then log("Lesefehler: "..tostring(err)) else log("SERVER-LOAD: "..tostring(#M.courses).." Hofkurse geladen von "..tostring(path)) end
end
function M.persist()
    if remoteClient() then return false,"Nur der Server kann Hofkurse speichern" end
    M.ensureLoaded()
    local path=filename()
    if not path or type(createXMLFile)~="function" then return false,"Spielstand-Verzeichnis nicht verfuegbar" end
    local ok,err=pcall(function()
        local xml=createXMLFile("TerraLineCourses",path,"terraline")
        if xml==nil or xml==0 then error("XML konnte nicht erstellt werden") end
        local n=0
        for fieldId,name in pairs(M.fieldNames) do
            local k=string.format("terraline.fields.field(%d)",n)
            setXMLInt(xml,k.."#id",fieldId);setXMLString(xml,k.."#name",name)
            n=n+1
        end
        for i,c in ipairs(M.courses) do
            local k=string.format("terraline.courses.course(%d)",i-1)
            setXMLInt(xml,k.."#id",c.id);setXMLInt(xml,k.."#farmId",c.farmId)
            setXMLInt(xml,k.."#fieldId",c.fieldId or 0)
            setXMLString(xml,k.."#name",c.name)
            setXMLFloat(xml,k.."#ax",c.ax);setXMLFloat(xml,k.."#az",c.az)
            setXMLFloat(xml,k.."#bx",c.bx);setXMLFloat(xml,k.."#bz",c.bz)
            setXMLFloat(xml,k.."#width",c.width or 0)
            setXMLFloat(xml,k.."#offset",c.offset or 0)
        end
        local result=saveXMLFile(xml)
        if type(delete)=="function" then delete(xml) end
        if result==false then error("saveXMLFile gab false zurueck") end
    end)
    if not ok then log("Speicherfehler: "..tostring(err));return false,"Kursdatei konnte nicht geschrieben werden" end
    if type(fileExists)=="function" and not fileExists(path) then
        log("FEHLER: Kursdatei nach Speicherung nicht auffindbar: "..path)
        return false,"Kursdatei nach Speicherung fehlt"
    end
    return true,"Im Hof-Spielstand gespeichert"
end

-- FS25 saves may temporarily redirect missionInfo.savegameDirectory.
-- Keep our authoritative course table and the original slot path stable;
-- write to that original slot again after the GIANTS save completes.
function M.installSaveHook()
    if M.saveHookInstalled then return true end
    if type(FSBaseMission)~="table" or type(FSBaseMission.saveSavegame)~="function"
       or type(Utils)~="table" or type(Utils.appendedFunction)~="function" then
        return false
    end
    FSBaseMission.saveSavegame=Utils.appendedFunction(FSBaseMission.saveSavegame,function(mission,...)
        if g_server==nil or mission~=g_currentMission then return end
        local ok,msg=M.persist()
        if ok then
            log("SERVER-SAVE-HOOK: "..tostring(#M.courses).." Hofkurse in persistentem Spielstand "..tostring(filename()).." geschrieben")
        else
            log("SERVER-SAVE-HOOK FEHLER: "..tostring(msg))
        end
    end)
    M.saveHookInstalled=true
    log("SERVER-SAVE-HOOK installiert (FSBaseMission.saveSavegame)")
    return true
end
-- Farm changes are LOCAL player changes, even when this player is also the host.
-- The shared server course database is never cleared by a farm switch.
-- A/B and steering belong to the local working context, not the shared farm list.
function M.watchLocalFarm()
    local farmId=M.getFarmId()
    local marker=farmId or false
    if M.observedFarmId==nil then
        M.observedFarmId=marker
        return
    end
    if M.observedFarmId==marker then return end
    local previous=M.observedFarmId
    M.observedFarmId=marker
    M.activeCourseName=nil
    M.pendingSave=nil
    M.lastServerMessage=nil
    M.pollTime=10000
    if remoteClient() then
        -- Cache only previously server-confirmed snapshots, separately per farm.
        -- Never destroy the old farm's list merely because the player changes farm.
        -- Server still owns the data; the next snapshot replaces this cached list.
        M.courses=(M.cachedCoursesByFarm or {})[farmId] or {}
        M.clientFarmId=farmId
        M.awaitingFarmSnapshot=farmId
        log(string.format("Hof %s: %d bestaetigte Kurse aus lokalem Hof-Cache angezeigt; Serverabgleich ausstehend",
            tostring(farmId),#M.courses))
    end
    if GPSSteeringController then GPSSteeringController.stop("Hofwechsel: GPS aus") end
    if GPSABLineManager then GPSABLineManager.clear() end
    if GPSTrackGenerator then GPSTrackGenerator.reset() end
    if GPSTrackPosition then GPSTrackPosition.reset() end
    if GPSAutoMirror and GPSAutoMirror.reset then GPSAutoMirror.reset() end
    if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.reset then GPSDeviceOffsetAuto.reset() end
    if GPSImplementDetector then GPSImplementDetector.override=nil end
    if GPSMenu and GPSMenu.screen then
        GPSMenu.screen.page3Selected=1
        GPSMenu.screen.page3Scroll=0
        GPSMenu.screen.page3PendingDelete=nil
        GPSMenu.screen.page3Message="Hofwechsel: GPS-Kurs und A/B-Referenz zurueckgesetzt"
    end
    -- Power is client-local and farm-specific; switching farms must not
    -- inherit the last visited farm's ON state.
    if GPSFieldTest and GPSFieldTest.syncPowerForFarm then
        GPSFieldTest:syncPowerForFarm(farmId)
    end
    log("Hofwechsel "..tostring(previous).." -> "..tostring(marker)..": lokale GPS-Spur entfernt")
end

function M.pollNetwork(dt)
    if not remoteClient() then return end
    local farmId=M.getFarmId()
    if farmId~=M.clientFarmId then
        -- Also covers delayed farm assignment at client join.
        M.courses=(M.cachedCoursesByFarm or {})[farmId] or {}
        M.activeCourseName=nil;M.clientFarmId=farmId
        M.awaitingFarmSnapshot=farmId
        M.pollTime=10000 -- Request without waiting for a manual save.
    end
    if not validFarm(farmId) then return end
    M.pollTime=(M.pollTime or 0)+math.max(0,dt or 0)
    -- Periodic farm-scoped pull also updates other farm workers without leaking
    -- server data via an unfiltered global broadcast. Late joins are supported.
    if M.pollTime>=10000 then
        if GPSFarmCourseEvent and GPSFarmCourseEvent.sendToServer(GPSFarmCourseEvent.REQUEST) then
            if M.awaitingFarmSnapshot==farmId then
                log("Hof "..tostring(farmId)..": Server-Kursliste angefordert (Cache bleibt bis zur Antwort sichtbar)")
            end
            M.pollTime=0
        end
    end
end
function M.receiveSnapshot(payload)
    if not remoteClient() or type(payload)~="table" then return end
    if payload.farmId~=M.getFarmId() then
        -- A delayed response after farm switch must never replace another farm's list.
        log("Veraltete Server-Kursliste fuer Hof "..tostring(payload.farmId).." ignoriert")
        return
    end
    local list={}
    for _,c in ipairs(payload.courses or {}) do
        if validNum(c.ax) and validNum(c.az) and validNum(c.bx) and validNum(c.bz)
            and type(c.name)=="string" and #c.name<=48 then
            c.farmId=payload.farmId
            list[#list+1]=c
        end
    end
    -- Replacing the cache (including an empty snapshot) makes the server
    -- authoritative, while preserving other farms' confirmed snapshots.
    M.cachedCoursesByFarm=M.cachedCoursesByFarm or {}
    M.cachedCoursesByFarm[payload.farmId]=list
    M.courses=list
    M.clientFarmId=payload.farmId
    M.awaitingFarmSnapshot=nil
    log(string.format("Hof %d: %d Kurse vom Server empfangen und zwischengespeichert",payload.farmId,#list))
end
-- The client displays a saved name ONLY after the authoritative server has
-- confirmed writing valid A/B coordinates. A sent request is not a save.
function M.receiveResult(payload)
    if not remoteClient() or type(payload)~="table" then return end
    -- Farm-ID 0 is an explicit rejection when the server could not establish
    -- the sender's farm; accept it only while waiting for our own save reply.
    if payload.farmId~=M.getFarmId() and not (payload.farmId==0 and M.pendingSave) then return end
    local message=tostring(payload.message or "Serverantwort fehlt"):sub(1,180)
    M.lastServerMessage=message
    if payload.operation==GPSFarmCourseEvent.SAVE then
        if payload.ok and M.pendingSave and M.pendingSave.farmId==payload.farmId then
            M.activeCourseName=M.pendingSave.name
        end
        M.pendingSave=nil
    end
    if GPSMenu and GPSMenu.screen then GPSMenu.screen.page3Message=message end
    log((payload.ok and "MP bestaetigt: " or "MP abgelehnt: ")..message)
end

local function addCourse(farmId, proposed)
    if not validFarm(farmId) then return false,"Keinem Hof zugeordnet" end
    if type(proposed)~="table" then return false,"Ungültige Kursdaten" end
    local name=cleanName(proposed.name)
    if name=="" then return false,"Kursname fehlt" end
    local ax,az,bx,bz=proposed.ax,proposed.az,proposed.bx,proposed.bz
    if not (validNum(ax) and validNum(az) and validNum(bx) and validNum(bz)) then
        return false,"Ungueltige A/B Koordinaten"
    end
    local dist=(bx-ax)^2+(bz-az)^2
    if dist<400 or dist>100000000 then return false,"A/B Abstand ausserhalb der Grenzen" end
    local width,offset=tonumber(proposed.width),tonumber(proposed.offset)
    if not width or width~=width or width<0 or width>60 then return false,"Ungueltige Arbeitsbreite" end
    if not offset or offset~=offset or math.abs(offset)>1000 then return false,"Ungueltiger Versatz" end
    if #matchingCourses(farmId)>=256 or M.nextId>65535 then return false,"Hof-Kursspeicher voll" end
    local c={id=M.nextId,farmId=farmId,fieldId=0,name=name,
        ax=ax,az=az,bx=bx,bz=bz,width=width,offset=offset}
    M.nextId=M.nextId+1
    M.courses[#M.courses+1]=c
    local ok,msg=M.persist()
    if not ok then table.remove(M.courses,#M.courses);M.nextId=M.nextId-1;return false,msg end
    return true,"Kurs '"..name.."' im Hof gespeichert"
end
local function removeCourse(farmId,id)
    for i,c in ipairs(M.courses) do
        if c.id==id and c.farmId==farmId then
            table.remove(M.courses,i)
            local ok,msg=M.persist()
            if not ok then table.insert(M.courses,i,c);return false,msg end
            return true,"Hofkurs geloescht"
        end
    end
    return false,"Kurs nicht vorhanden oder fremder Hof"
end
function M.handleClientRequest(connection,operation,payload)
    if g_server==nil or not connection then return end
    local mission=g_currentMission
    local player=mission and type(mission.getPlayerByConnection)=="function" and mission:getPlayerByConnection(connection)
    local farmId=player and player.farmId
    if not validFarm(farmId) then
        log("MP Anfrage ohne gueltige Hofzugehoerigkeit abgelehnt (Player="..tostring(player)..")")
        if operation==GPSFarmCourseEvent.SAVE or operation==GPSFarmCourseEvent.DELETE then
            GPSFarmCourseEvent.sendResult(connection,operation,0,false,"Hofzugehoerigkeit serverseitig nicht erkannt")
        end
        return
    end
    M.ensureLoaded()
    if operation==GPSFarmCourseEvent.SAVE then
        local ok,msg=addCourse(farmId,payload)
        log("Hof "..farmId.." Speichern: "..tostring(msg))
        GPSFarmCourseEvent.sendResult(connection,operation,farmId,ok,msg)
    elseif operation==GPSFarmCourseEvent.DELETE then
        local ok,msg=removeCourse(farmId,payload.id)
        log("Hof "..farmId.." Loeschen: "..tostring(msg))
        GPSFarmCourseEvent.sendResult(connection,operation,farmId,ok,msg)
    elseif operation~=GPSFarmCourseEvent.REQUEST then
        return
    else
        log("MP REQUEST Hof "..tostring(farmId)..": "..tostring(#matchingCourses(farmId)).." Kurse an Client")
    end
    GPSFarmCourseEvent.sendSnapshot(connection,farmId,matchingCourses(farmId))
end

function M.getActiveName()
    if M.observedFarmId~=nil and M.observedFarmId~=(M.getFarmId() or false) then return nil end
    return M.activeCourseName
end
function M.listAll()
    M.ensureLoaded()
    return matchingCourses(M.getFarmId())
end
local function hasAB()
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not a or not b then return nil,nil end
    if (b.x-a.x)^2+(b.z-a.z)^2<100 then return nil,nil end
    return a,b
end
function M.getAngle()
    local a,b=hasAB()
    if not a then return nil end
    -- North = 0 degrees; clockwise via East = 90.
    local deg=math.deg(math.atan2(b.x-a.x,b.z-a.z))
    return (deg+360)%360
end
local function refresh()
    GPSSteeringController.stop("Kursrichtung geaendert")
    GPSTrackGenerator.reset();GPSTrackPosition.reset()
    if GPSAutoMirror and type(GPSAutoMirror.reset)=="function" then GPSAutoMirror.reset() end
end
function M.setAngle(degrees)
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local speed=vehicle and type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then return false,"Winkel bitte im Stillstand aendern" end
    local angle=tonumber((tostring(degrees or ""):gsub(",",".")))
    if not angle or angle~=angle then return false,"Winkel muss eine Zahl sein" end
    local a,b=hasAB()
    if not a then
        a=GPSABLineManager.a
        if not a then
            local point,err=GPSABLineManager.getVehiclePoint()
            if not point then return false,"Kein Fahrzeug zum Erstellen einer Winkelspur" end
            a=point
        end
        b={x=a.x,z=a.z+30}
    end
    angle=angle%360
    local dx,dz=b.x-a.x,b.z-a.z
    local length=math.sqrt(dx*dx+dz*dz)
    local rad=math.rad(angle)
    local targetB={x=a.x+length*math.sin(rad),z=a.z+length*math.cos(rad)}
    -- Keep point A as pivot. This changes direction, not lateral offset.
    refresh()
    if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled and type(GPSDeviceOffsetAuto.setEnabled)=="function" then
        GPSDeviceOffsetAuto.setEnabled(false)
    end
    GPSABLineManager.a=a
    GPSABLineManager.b=targetB
    GPSABLineManager.offsetMeters=0
    M.activeCourseName=nil
    log(string.format("Winkel %.2f Grad, A bleibt fest; Versatz auf 0",angle))
    return true,string.format("Kursrichtung %.2f Grad; GPS ausgeschaltet",angle)
end
function M.rotate90()
    local angle=M.getAngle()
    if angle==nil then return false,"Zuerst A/B setzen" end
    return M.setAngle(angle+90)
end
function M.saveCurrent(name)
    M.ensureLoaded()
    local a,b=hasAB()
    if not a then return false,"Erst A/B-Linie setzen" end
    name=cleanName(name)
    if name=="" then return false,"Kursname darf nicht leer sein" end
    local farmId=M.getFarmId()
    if not validFarm(farmId) then return false,"Du bist keinem Hof zugeordnet" end
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local width=GPSImplementDetector.getWidth(vehicle)
    local proposed={name=name,ax=a.x,az=a.z,bx=b.x,bz=b.z,
        width=type(width)=="number" and width or 0,offset=GPSABLineManager.offsetMeters or 0}
    if remoteClient() then
        if not (GPSFarmCourseEvent and GPSFarmCourseEvent.sendToServer(GPSFarmCourseEvent.SAVE,proposed)) then
            return false,"Serververbindung nicht bereit"
        end
        M.pendingSave={name=name,farmId=farmId}
        return true,"Kurs an Server gesendet – noch NICHT gespeichert"
    end
    local ok,msg=addCourse(farmId,proposed)
    if ok then M.activeCourseName=name end
    return ok,msg
end
function M.loadCourse(course)
    M.ensureLoaded()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local speed=vehicle and type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then return false,"Bitte zum Laden des Kurses anhalten" end
    if type(course)~="table" or not validNum(course.ax) or not validNum(course.az)
        or not validNum(course.bx) or not validNum(course.bz) then return false,"Kurs ungueltig" end
    local farmId=M.getFarmId()
    if not validFarm(farmId) or course.farmId~=farmId then return false,"Kurs gehoert einem anderen Hof" end
    local found=false
    for _,existing in ipairs(M.listAll()) do
        if existing.id==course.id then found=true;break end
    end
    if not found then return false,"Kurs nicht im Hofspeicher vorhanden" end
    refresh()
    if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled and type(GPSDeviceOffsetAuto.setEnabled)=="function" then
        GPSDeviceOffsetAuto.setEnabled(false)
    end
    GPSABLineManager.a={x=course.ax,z=course.az};GPSABLineManager.b={x=course.bx,z=course.bz}
    GPSABLineManager.offsetMeters=course.offset or 0
    if GPSImplementDetector then
        GPSImplementDetector.override=course.width and course.width>=0.5 and course.width<=60 and course.width or nil
    end
    M.activeCourseName=course.name
    GPSLogger.info("TerraLine Kurs geladen: "..course.name)
    return true,"Kurs '"..course.name.."' geladen, GPS aus"
end
function M.deleteCourse(course)
    M.ensureLoaded()
    local farmId=M.getFarmId()
    if not validFarm(farmId) then return false,"Du bist keinem Hof zugeordnet" end
    if type(course)~="table" or course.farmId~=farmId then
        return false,"Nur Kurse des eigenen Hofs loeschen"
    end
    if remoteClient() then
        if not (GPSFarmCourseEvent and GPSFarmCourseEvent.sendToServer(GPSFarmCourseEvent.DELETE,{id=course.id})) then
            return false,"Serververbindung nicht bereit"
        end
        return true,"Loeschung an Server gesendet – Bestaetigung abwarten"
    end
    return removeCourse(farmId,course.id)
end
