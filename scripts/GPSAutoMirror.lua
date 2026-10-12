-- Automatically reverse a driver-relative lateral shift when the tractor
-- heads back along the A/B course. Changes only the existing A/B guidance
-- translation; in v0.9.9.29 this moves the complete lane corridor.
-- Never triggers from backing briefly in reverse gear or while turning.
GPSAutoMirror={enabled=true,lastVehicle=nil,lastA=nil,lastB=nil,courseUx=nil,courseUz=nil,
               confirmedDir=nil,candidateDir=nil,candidateMs=0,candidateDistance=0,
               lastX=nil,lastZ=nil,lastLog=nil}
function GPSAutoMirror.reset()
    -- Reset STATE IN PLACE. Replacing this table deletes update()/reset(),
    -- causing the game update callback to fail every single frame.
    local s=GPSAutoMirror
    s.lastVehicle=nil
    s.lastA=nil
    s.lastB=nil
    s.courseUx=nil
    s.courseUz=nil
    s.confirmedDir=nil
    s.candidateDir=nil
    s.candidateMs=0
    s.candidateDistance=0
    s.lastX=nil
    s.lastZ=nil
    s.lastLog=nil
end
local function clearCandidate(s)
    s.candidateDir=nil;s.candidateMs=0;s.candidateDistance=0
    s.lastX=nil;s.lastZ=nil
end
function GPSAutoMirror.update(dt,vehicle)
    local s=GPSAutoMirror
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not s.enabled or not a or not b or not vehicle then
        if s.lastVehicle or s.lastA or s.lastB then GPSAutoMirror.reset() end
        return
    end
    local dx,dz=b.x-a.x,b.z-a.z
    local len=math.sqrt(dx*dx+dz*dz)
    if len<10 then return end
    local ux,uz=dx/len,dz/len
    local swapped=(s.lastA==b and s.lastB==a and a~=b)
    local courseChanged=(s.lastA~=a or s.lastB~=b or s.lastVehicle~=vehicle)
    if courseChanged then
        if swapped and s.lastVehicle==vehicle and s.confirmedDir then
            -- A/B manually reversed without rotating the vehicle: stored
            -- offset already negated by the UI; do not auto flip it again.
            s.confirmedDir=-s.confirmedDir
        else
            s.confirmedDir=nil
        end
        s.lastA=a;s.lastB=b;s.lastVehicle=vehicle
        clearCandidate(s)
    end
    s.courseUx,s.courseUz=ux,uz
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node or type(localDirectionToWorld)~="function" then return end
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    if type(fx)~="number" or type(fz)~="number" then return end
    local fl=math.sqrt(fx*fx+fz*fz)
    if fl<0.5 then return end
    local dot=(fx*ux+fz*uz)/fl
    -- Only consider aligned travel (approx 26 degrees tolerance).
    if math.abs(dot)<0.90 then clearCandidate(s);return end
    local dir=dot>=0 and 1 or -1
    if s.confirmedDir==nil then
        -- The direction in which a user initially sets an offset is the
        -- reference direction, including when the vehicle is stationary.
        s.confirmedDir=dir
        clearCandidate(s)
        return
    end
    if dir==s.confirmedDir then clearCandidate(s);return end
    -- Moving forward on the opposite pass, not merely reversing in the cab.
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed<2.5 or (type(vehicle.movingDirection)=="number" and vehicle.movingDirection< -0.1)
        or (GPSSteeringController and GPSSteeringController.enabled) then
        clearCandidate(s);return
    end
    local x,_,z=getWorldTranslation(node)
    if s.candidateDir~=dir then
        s.candidateDir=dir;s.candidateMs=0;s.candidateDistance=0
        s.lastX=x;s.lastZ=z
        return
    end
    s.candidateMs=s.candidateMs+math.max(0,dt or 0)
    if s.lastX and s.lastZ then
        local dist=math.sqrt((x-s.lastX)^2+(z-s.lastZ)^2)
        -- Count only plausible motion; teleports must not trigger.
        if dist<3 then s.candidateDistance=s.candidateDistance+dist end
    end
    s.lastX=x;s.lastZ=z
    -- Both sustained forward alignment and real movement are required.
    if s.candidateMs<650 or s.candidateDistance<1.2 then return end
    local old=GPSABLineManager.offsetMeters or 0
    if math.abs(old)>0.0001 then
        local shiftDirection=old>0 and -1 or 1
        local ok,msg=GPSABLineManager.shift(shiftDirection,2*math.abs(old))
        if not ok then
            GPSLogger.info("Auto-Wende: "..tostring(msg));clearCandidate(s);return
        end
        GPSABLineManager.offsetMeters=-old
        if GPSDeviceOffsetAuto and type(GPSDeviceOffsetAuto.onCourseMirrored)=="function" then GPSDeviceOffsetAuto.onCourseMirrored() end
        local width=GPSImplementDetector.getWidth(vehicle)
        if type(width)=="number" and width>0 then
            GPSTrackGenerator.generate(nil,a,b,width)
            GPSTrackGenerator.cacheKey=tostring(a)..":"..tostring(b)..":"..tostring(width)
        end
        GPSTrackPosition.lastUpdate=150
        GPSLogger.info(string.format("Auto-Wende: Richtung %s | Versatz A/B %+.2f -> %+.2f m | Spur unveraendert",
                         dir>0 and "A nach B" or "B nach A",old,-old))
    end
    s.confirmedDir=dir
    clearCandidate(s)
end
