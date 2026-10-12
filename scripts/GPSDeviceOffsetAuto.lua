-- Optional, guarded automatic adjustment for asymmetric implement work areas.
-- OFF by default. Separate bookkeeping keeps manual and detected offsets apart.
-- Changes the existing A/B guidance translation, never SteeringController.lua.
GPSDeviceOffsetAuto={enabled=false,applied=0,lastA=nil,lastB=nil,lastVehicle=nil,
                     candidate=nil,candidateCount=0,lastStatus="Aus",clock=0}
local D=GPSDeviceOffsetAuto
local function refresh()
    if GPSTrackGenerator then GPSTrackGenerator.cacheKey=nil end
    if GPSTrackPosition then GPSTrackPosition.lastUpdate=150 end
end
local function applyDelta(delta)
    if math.abs(delta)<0.005 then return true end
    local ok,msg=GPSABLineManager.shift(delta>0 and 1 or -1,math.abs(delta))
    if not ok then return false,msg end
    refresh()
    return true
end
function D.reset()
    D.enabled=false;D.applied=0;D.lastA=nil;D.lastB=nil;D.lastVehicle=nil
    D.candidate=nil;D.candidateCount=0;D.lastStatus="Aus";D.clock=0
end
function D.onCourseMirrored()
    D.applied=-(D.applied or 0)
    D.lastA=GPSABLineManager.a
    D.lastB=GPSABLineManager.b
    D.candidate=nil;D.candidateCount=0
end
function D.setEnabled(state)
    if GPSSteeringController and GPSSteeringController.enabled then
        return false,"Geraete-Auto: GPS-Lenkung vorher ausschalten"
    end
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local speed=vehicle and type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then return false,"Geraete-Auto: Zum Umschalten anhalten" end
    if not state and (D.applied or 0)~=0 then
        local ok,msg=applyDelta(-D.applied)
        if not ok then return false,msg end
        D.applied=0
    end
    D.enabled=state==true
    D.candidate=nil;D.candidateCount=0;D.clock=1000
    D.lastStatus=D.enabled and "Messung abwarten (GPS aus, anhalten)" or "Aus"
    if GPSLogger then GPSLogger.info("Geraete-Auto "..(D.enabled and "AN" or "AUS")) end
    return true,"Geraete-Auto "..(D.enabled and "AN: Messung abwarten" or "AUS: Zusatzversatz entfernt")
end
function D.update(dt,vehicle)
    if not D.enabled then return end
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if a~=D.lastA or b~=D.lastB or vehicle~=D.lastVehicle then
        -- New A/B points start without offset; never "undo" a shift on a new course.
        D.lastA=a;D.lastB=b;D.lastVehicle=vehicle
        D.applied=0;D.candidate=nil;D.candidateCount=0
    end
    if not a or not b or not vehicle then D.lastStatus="A/B oder Traktor fehlt";return end
    if GPSSteeringController and GPSSteeringController.enabled then
        D.lastStatus="GPS aktiv: Korrektur gesperrt";return
    end
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then D.lastStatus="Zum Nachstellen anhalten";return end
    D.clock=(D.clock or 0)+math.max(0,dt or 0)
    if D.clock<900 then return end
    D.clock=0
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node then D.lastStatus="Traktorkoordinaten fehlen";return end
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    local dx,dz=b.x-a.x,b.z-a.z
    local length=math.sqrt(dx*dx+dz*dz)
    if length<10 then return end
    local alignment=(fx*dx+fz*dz)/length
    if math.abs(alignment)<0.90 then D.lastStatus="A/B ausrichten";return end
    local dir=(GPSAutoMirror and GPSAutoMirror.enabled and GPSAutoMirror.confirmedDir) or (alignment>0 and 1 or -1)
    local center,desc,complete=GPSDeviceOffsetProbe.getData(vehicle)
    local target
    if center==nil then
        -- Unknown device: do not silently move any course. Keep last known
        -- correction until the user switches it off or a valid new measurement.
        D.lastStatus="Keine Geraetegeometrie erkannt"
        return
    end
    if not complete or math.abs(center)>2.0 then
        D.lastStatus="Geraet nicht sicher erkannt"
        return
    end
    local width=GPSImplementDetector.getWidth(vehicle) or 3
    -- A measured device center LEFT (-x) means the tractor must steer RIGHT
    -- relative to travel, hence a positive shift for A->B.
    target= -center*dir
    if math.abs(target)<0.03 then target=0 end
    -- Never move the guidance line beyond the nominal working-width corridor.
    local maxAuto=math.min(1.50,math.max(0,width*0.5-0.05))
    if math.abs(target)>maxAuto then
        D.lastStatus=string.format("Messung %+.2fm ausserhalb Korridor",target)
        return
    end
    if D.candidate~=nil and math.abs(D.candidate-target)<0.04 then
        D.candidateCount=D.candidateCount+1
    else
        D.candidate=target;D.candidateCount=1
    end
    if D.candidateCount<2 then D.lastStatus="Geraetewert stabilisieren";return end
    local delta=target-(D.applied or 0)
    if math.abs(delta)>=0.03 then
        local ok,msg=applyDelta(delta)
        if not ok then D.lastStatus=tostring(msg);return end
        D.applied=target
        GPSLogger.info(string.format("Geraete-Auto uebernommen: Arbeitsmitte=%+.2f m, Richtung=%d, Korrektur=%+.2f m, Delta=%+.2f m",center,dir,target,delta))
    end
    D.lastStatus=string.format("Aktiv: Arbeitsmitte %+.2fm, Korrektur %+.2fm",center,D.applied or 0)
end
