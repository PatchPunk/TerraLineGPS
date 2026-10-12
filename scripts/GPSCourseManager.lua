-- TerraLine GPS: named independent A/B courses saved per savegame. No field detection.
-- Self-contained persistence; never changes SteeringController.lua.
GPSCourseManager={courses={},fieldNames={},loadedPath=nil,nextId=1,activeCourseName=nil}
local M=GPSCourseManager
local function log(s) if GPSLogger and GPSLogger.info then GPSLogger.info("TerraLine Kurse: "..tostring(s)) end end
local function directory()
    local mission=g_currentMission
    local info=mission and mission.missionInfo
    return info and info.savegameDirectory
end
local function filename()
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
function M.reset()
    M.courses={};M.fieldNames={};M.loadedPath=nil;M.nextId=1
    M.activeCourseName=nil
end
function M.ensureLoaded()
    local path=filename()
    if not path or M.loadedPath==path then return end
    M.courses={};M.fieldNames={};M.nextId=1;M.loadedPath=path
    if type(fileExists)~="function" or not fileExists(path) or type(loadXMLFile)~="function" then return end
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
            local fieldId=getXMLInt(xml,k.."#fieldId")
            local ax,az,bx,bz=getXMLFloat(xml,k.."#ax"),getXMLFloat(xml,k.."#az"),getXMLFloat(xml,k.."#bx"),getXMLFloat(xml,k.."#bz")
            if validNum(ax) and validNum(az) and validNum(bx) and validNum(bz) then
                M.courses[#M.courses+1]={id=id,fieldId=fieldId or 0,name=cleanName(getXMLString(xml,k.."#name")),
                    ax=ax,az=az,bx=bx,bz=bz,width=getXMLFloat(xml,k.."#width"),
                    offset=getXMLFloat(xml,k.."#offset") or 0}
                M.nextId=math.max(M.nextId,id+1)
            end
        end
    end)
    if type(delete)=="function" then pcall(delete,xml) end
    if not success then log("Lesefehler: "..tostring(err)) else log(tostring(#M.courses).." Kurse geladen") end
end
function M.persist()
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
            setXMLInt(xml,k.."#id",c.id);setXMLInt(xml,k.."#fieldId",c.fieldId)
            setXMLString(xml,k.."#name",c.name)
            setXMLFloat(xml,k.."#ax",c.ax);setXMLFloat(xml,k.."#az",c.az)
            setXMLFloat(xml,k.."#bx",c.bx);setXMLFloat(xml,k.."#bz",c.bz)
            setXMLFloat(xml,k.."#width",c.width or 0)
            setXMLFloat(xml,k.."#offset",c.offset or 0)
        end
        saveXMLFile(xml)
        if type(delete)=="function" then delete(xml) end
    end)
    if not ok then log("Speicherfehler: "..tostring(err));return false,"Kursdatei konnte nicht geschrieben werden" end
    return true,"In diesem Spielstand gespeichert"
end
function M.getActiveName()
    return M.activeCourseName
end
function M.listAll()
    M.ensureLoaded()
    local result={}
    for _,course in ipairs(M.courses) do result[#result+1]=course end
    return result
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
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local width=GPSImplementDetector.getWidth(vehicle)
    local c={id=M.nextId,fieldId=0,name=name,ax=a.x,az=a.z,bx=b.x,bz=b.z,
        width=type(width)=="number" and width or 0,offset=GPSABLineManager.offsetMeters or 0}
    M.nextId=M.nextId+1
    M.courses[#M.courses+1]=c
    M.activeCourseName=name
    local ok,msg=M.persist()
    return ok,ok and ("Kurs '"..name.."' gespeichert") or msg
end
function M.loadCourse(course)
    M.ensureLoaded()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local speed=vehicle and type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then return false,"Bitte zum Laden des Kurses anhalten" end
    if type(course)~="table" or not validNum(course.ax) or not validNum(course.bx) then return false,"Kurs ungueltig" end
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
    for i,c in ipairs(M.courses) do
        if c.id==course.id then
            table.remove(M.courses,i)
            local ok,msg=M.persist()
            return ok,ok and "Kurs geloescht" or msg
        end
    end
    return false,"Kurs nicht gefunden"
end
