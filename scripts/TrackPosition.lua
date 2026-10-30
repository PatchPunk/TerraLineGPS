-- Reference-locked nearest lane: A/B=track 0 (shown as GPS 1).
-- No field polygon, field ID, contour or segment snapping.
GPSTrackPosition={track=nil,offset=nil,side=nil,valid=false,info="Warte auf A/B",lastUpdate=0,
    numberingOrigin=0,numberingA=nil,numberingB=nil,lastVehicle=nil}
-- Display numbering is independent of the physical nearest-track index.
-- Never move saved A/B points or alter steering targets to reset a label.
function GPSTrackPosition.getDisplayNumber(physicalTrack)
    if type(physicalTrack)~="number" then return nil end
    local s=GPSTrackPosition
    local origin=0
    if s.numberingA==GPSABLineManager.a and s.numberingB==GPSABLineManager.b then
        origin=s.numberingOrigin or 0
    end
    local relative=physicalTrack-origin
    return relative>=0 and relative+1 or relative-1
end
function GPSTrackPosition.resetLaneNumbering(vehicle)
    local s=GPSTrackPosition
    if not vehicle or not GPSABLineManager.a or not GPSABLineManager.b then
        return false,"GPS: Erst A/B-Spur erstellen und Traktor waehlen"
    end
    -- Do not use a cached track of another vehicle or a 150-ms stale position.
    s.lastUpdate=150
    s.update(0,vehicle)
    if not s.valid or type(s.track)~="number" then
        return false,"GPS: Nächste Spur nicht ermittelbar"
    end
    s.numberingOrigin=s.track
    s.numberingA=GPSABLineManager.a
    s.numberingB=GPSABLineManager.b
    local n=s.getDisplayNumber(s.track)
    s.info=string.format("Spur %d | %.0f cm %s",n,math.abs(s.offset)*100,s.side)
    return true,string.format("GPS Spurnummerierung zurueckgesetzt: physische Spur %d ist jetzt Spur 1",s.track)
end
function GPSTrackPosition.reset()
    local s=GPSTrackPosition
    s.track=nil;s.offset=nil;s.side=nil;s.valid=false;s.info="Warte auf A/B";s.lastUpdate=0
    s.numberingOrigin=0;s.numberingA=nil;s.numberingB=nil;s.lastVehicle=nil
end
function GPSTrackPosition.update(dt,vehicle)
    local s=GPSTrackPosition
    s.lastUpdate=(s.lastUpdate or 0)+(dt or 0)
    if s.lastVehicle~=vehicle then s.lastUpdate=150 end
    if s.lastUpdate<150 then return end
    s.lastVehicle=vehicle
    s.lastUpdate=0
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not vehicle or not a or not b then s.reset();return end
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node then s.reset();return end
    local x,_,z=getWorldTranslation(node)
    if type(x)~="number" or type(z)~="number" then s.reset();return end
    local dx,dz=b.x-a.x,b.z-a.z
    local len=math.sqrt(dx*dx+dz*dz)
    if len<20 then s.reset();return end
    local width=GPSImplementDetector.getWidth(vehicle)
    if type(width)~="number" or width<=0 then s.reset();return end
    local nx,nz=-dz/len,dx/len
    local live=(x-a.x)*nx+(z-a.z)*nz
    -- When implement-auto is active, the physically relevant lane is the
    -- working center of the implement rather than the tractor's center.
    -- A/B points, lane artwork and stored manual shifts are untouched.
    local autoCorrection=0
    if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled then
        local fx,_,fz=localDirectionToWorld(node,0,0,1)
        local dir=(fx*dx+fz*dz)>=0 and 1 or -1
        autoCorrection=GPSDeviceOffsetAuto.getCorrection(vehicle,dir)
        if autoCorrection==nil then
            s.track=nil;s.offset=nil;s.side=nil;s.valid=false
            s.info="Geraete-Auto: Arbeitsmitte einmessen"
            return
        end
    end
    local workLive=live-autoCorrection
    local track=math.floor(workLive/width+0.5)
    local deviation=workLive-track*width
    -- Signed A/B deviation uses a fixed map normal; the HUD must instead
    -- report left/right from the driver's CURRENT heading (return pass too).
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    local driverDir=(type(fx)=="number" and type(fz)=="number" and
        (fx*dx+fz*dz)<0) and -1 or 1
    s.track=track;s.offset=deviation;s.side=(deviation*driverDir)>=0 and "links" or "rechts";s.valid=true
    local number=s.getDisplayNumber(track)
    s.info=string.format("Spur %d | %.0f cm %s",number,math.abs(deviation)*100,s.side)
end
