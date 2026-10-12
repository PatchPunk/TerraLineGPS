-- GPS v0.9.4: experimental straight-pass steering, no throttle / brakes / turns.
-- Steering axis verified with v0.9.2: negative = left, positive = right.
GPSSteeringController={enabled=false,vehicle=nil,reason="Aus",lastValue=0,lastCross=0,lockedTrack=nil,hookInstalled=false,logClock=0,guardStart=nil,guardClock=0,waitingForMotion=false}
local C=GPSSteeringController
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function log(msg) if GPSLogger then GPSLogger.info("GPS-LENK "..msg) end end
function C.stop(reason)
    if C.enabled then log("AUS: "..tostring(reason)) end
    C.enabled=false; C.vehicle=nil; C.lastValue=0; C.lockedTrack=nil; C.reason=reason or "Aus"; C.logClock=0; C.guardStart=nil; C.guardClock=0; C.waitingForMotion=false
end
function C.toggle(vehicle)
    if C.enabled then C.stop("Manuell ausgeschaltet"); return "GPS Lenkung AUS" end
    if not vehicle or not vehicle.spec_drivable then return "GPS: Kein lenkbares Fahrzeug" end
    if GPSSteeringDiagnostics and GPSSteeringDiagnostics.active then return "GPS: Erst Lenktest beenden" end
    if vehicle.spec_aiAutomaticSteering and vehicle.spec_aiAutomaticSteering.steeringEnabled then return "GPS: GIANTS Lenkassistent deaktivieren" end
    if not GPSABLineManager.a or not GPSABLineManager.b or not GPSTrackPosition.valid or GPSTrackPosition.track==nil then
        return "GPS: A/B und gueltige Spur erforderlich"
    end
    if not C.install(vehicle) then return "GPS: Lenk-Hook nicht verfuegbar" end
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>30 then return "GPS: Aktivierung nur bis 30 km/h" end
    C.vehicle=vehicle;C.enabled=true;C.lockedTrack=GPSTrackPosition.track;C.lastValue=0;C.logClock=0;C.guardStart=nil;C.guardClock=0;C.waitingForMotion=false;C.networkPathLogged=false
    C.reason="Aktiv | Spur "..tostring(C.lockedTrack)
    log("EIN: Spur "..tostring(C.lockedTrack).." bei "..string.format("%.1f km/h",speed))
    return "GPS Lenkung EIN | Spur "..tostring(C.lockedTrack)
end
function C.compute(vehicle,dt)
    if not C.enabled or vehicle~=C.vehicle then return nil end
    if not GPSABLineManager.a or not GPSABLineManager.b then
        C.stop("A/B verloren");return nil
    end
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    local dx,dz=b.x-a.x,b.z-a.z; local len=math.sqrt(dx*dx+dz*dz)
    if len<10 then C.stop("A/B ungueltig");return nil end
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node then C.stop("Fahrzeugposition fehlt");return nil end
    local x,_,z=getWorldTranslation(node)
    local vx,_,vz=localDirectionToWorld(node,0,0,1)
    local fl=math.sqrt(vx*vx+vz*vz)
    if fl<0.5 then C.stop("Fahrzeugrichtung ungueltig");return nil end
    vx,vz=vx/fl,vz/fl
    local ux,uz=dx/len,dz/len
    local dot=vx*ux+vz*uz
    local dir=dot>=0 and 1 or -1
    local targetX,targetZ=ux*dir,uz*dir
    -- Cross product with this coordinate order produces NEGATIVE heading for a
    -- target to the RIGHT. LS25 steering axis positive is RIGHT (verified in v0.9.2).
    local heading=math.atan2(vx*targetZ-vz*targetX,vx*targetX+vz*targetZ)
    if math.abs(heading)>0.35 then C.stop("Winkel groesser 20 Grad");return nil end
    local width=GPSImplementDetector.getWidth(vehicle)
    if not width or width<0.5 then C.stop("Arbeitsbreite fehlt");return nil end
    local nx,nz=-uz,ux
    local offset=(x-a.x)*nx+(z-a.z)*nz-C.lockedTrack*width
    if math.abs(offset)>math.min(1.2,width*0.42) then C.stop("Abweichung zu gross");return nil end
    -- Unbounded A/B guidance: no field-edge stop and no segment list.
    -- Empirical v0.9.3 logs: signed offset and heading ran AWAY from zero.
    -- Reverse BOTH feedback terms; check actual offset decrease in the safety watchdog.
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 5
    local gainScale=clamp(8/math.max(speed,3),0.55,1.25)
    local desired=clamp((heading*1.10-offset*dir*0.23)*gainScale,-0.22,0.22)
    -- Rate limit to avoid abrupt wheel movements. dt is milliseconds.
    local maxDelta=0.00035*clamp(dt or 16,1,100)
    local command=C.lastValue+clamp(desired-C.lastValue,-maxDelta,maxDelta)
    -- Early trend watchdog: prevents extended wrong-way correction if sign still wrong.
    -- Observe absolute lateral error over a moving 2.2-second window.
    if C.guardStart==nil then C.guardStart=math.abs(offset); C.guardClock=0 end
    C.guardClock=C.guardClock+(dt or 0)
    if C.guardClock>=2200 then
        local growth=math.abs(offset)-C.guardStart
        log(string.format("Trend: absStart=%.3f absNow=%.3f delta=%+.3f heading=%.3f cmd=%.3f",C.guardStart,math.abs(offset),growth,heading,command))
        if growth>0.24 and math.abs(command)>0.04 then
            C.stop("Sicherheitsstopp: Spurabweichung waechst"); return nil
        end
        C.guardStart=math.abs(offset); C.guardClock=0
    end
    C.lastValue=command;C.lastCross=offset
    C.reason=string.format("Spur %d | %d cm | Lenk %.2f | frei",C.lockedTrack,math.floor(math.abs(offset)*100+0.5),command)
    C.logClock=C.logClock+(dt or 0)
    if C.logClock>=1600 then
        C.logClock=0
        log(string.format("Spur=%d, speed=%.1f, offset=%.2f, heading=%.3f, steer=%.3f",C.lockedTrack,speed,offset,heading,command))
    end
    return command
end
-- v0.9.2 proved this per-vehicle hook actually reaches the tractor's steering.
function C.install(vehicle)
    if not vehicle or type(vehicle.updateVehiclePhysics)~="function" then return false end
    if C.hookedVehicles==nil then C.hookedVehicles=setmetatable({},{__mode="k"}) end
    if C.hookedVehicles[vehicle] then return true end
    local original=vehicle.updateVehiclePhysics
    local wrapper=function(self,axisForward,axisSide,doHandbrake,dt,...)
        if GPSSteeringDiagnostics then axisSide=GPSSteeringDiagnostics.physics(self,axisForward,axisSide,doHandbrake,dt) end
        if C.enabled and self==C.vehicle and not (GPSSteeringDiagnostics and GPSSteeringDiagnostics.active) then
            local speed=type(self.getLastSpeed)=="function" and math.abs(self:getLastSpeed()) or 0
            -- axisSide is raw player steering from game before applying our command.
            if speed>30 then
                C.stop("Geschwindigkeit ueber 30 km/h")
            elseif speed<2 then
                -- Paused at standstill (also while parked with handbrake):
                -- GPS stays ON, but NEVER sends steering corrections while stopped.
                -- Keep the chosen lane and start again without another key press.
                if not C.waitingForMotion then
                    C.waitingForMotion=true
                    C.reason="Aktiv (Stillstand) | Spur "..tostring(C.lockedTrack)
                    log("PAUSE: GPS bleibt beim Anhalten aktiv | Spur "..tostring(C.lockedTrack))
                end
                C.lastValue=0
                C.guardStart=nil
                C.guardClock=0
            elseif doHandbrake then
                C.stop("Handbremse waehrend Fahrt")
            elseif type(axisSide)=="number" and math.abs(axisSide)>0.25 then
                C.stop("Manueller Lenkeingriff")
            else
                if C.waitingForMotion then
                    C.waitingForMotion=false
                    log("FORTSETZEN: GPS lenkt nach dem Anfahren wieder | Spur "..tostring(C.lockedTrack))
                end
                local v=C.compute(self,dt)
                if v~=nil then axisSide=v end
            end
        end
        return original(self,axisForward,axisSide,doHandbrake,dt,...)
    end
    local ok,err=pcall(function() vehicle.updateVehiclePhysics=wrapper end)
    if not ok or vehicle.updateVehiclePhysics~=wrapper then
        log("Hook fehlgeschlagen: "..tostring(err));return false
    end
    C.hookedVehicles[vehicle]=original;C.hookInstalled=true
    if g_client~=nil and g_server==nil and type(vehicle.setSteeringInput)=="function" then
        local originalInput=vehicle.setSteeringInput
        vehicle.setSteeringInput=function(self,value,isAnalog,deviceCategory,...)
            if C.enabled and self==C.vehicle and type(value)=="number" and math.abs(value)>0.25 then
                C.stop("MP: Manueller Lenkeingriff")
            end
            return originalInput(self,value,isAnalog,deviceCategory,...)
        end
    end
    log("Fahrzeug-Hook aktiv: "..tostring(vehicle.getName and vehicle:getName() or vehicle))
    return true
end

-- Dedicated MP: Drivable:onUpdate runs on the driving CLIENT and transmits
-- spec_drivable.axisSide via the normal dirty update stream. On a remote
-- client the legacy updateVehiclePhysics hook may never run. Do not send
-- custom steering RPCs and do not change the server's vehicle state directly.
-- Only the locally entered vehicle receives commands.
function C.updateNetworkSteering(dt,vehicle)
    if g_client==nil or g_server~=nil or not C.enabled then return end
    if vehicle==nil or vehicle~=C.vehicle then C.stop("MP: Fahrzeug verlassen/gewechselt");return end
    if vehicle.isClient~=true or vehicle.spec_drivable==nil then
        C.stop("MP: Kein lokales Drivable-Fahrzeug");return
    end
    if type(vehicle.getIsEntered)=="function" and not vehicle:getIsEntered() then
        C.stop("MP: Fahrer ausgestiegen");return
    end
    local spec=vehicle.spec_drivable
    if type(vehicle.raiseDirtyFlags)~="function" or spec.dirtyFlag==nil then
        C.stop("MP: Lenkeingabe-Synchronisierung nicht verfuegbar");return
    end
    -- The normal local steering input callback is monitored by install().
    -- Manual movement above the threshold disengages GPS immediately.
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>30 then C.stop("MP: Geschwindigkeit ueber 30 km/h");return end
    if spec.doHandbrake and speed>=2 then C.stop("MP: Handbremse");return end
    if speed<2 then
        if not C.waitingForMotion then
            C.waitingForMotion=true
            log("MP: GPS wartet bei Stillstand auf Weiterfahrt")
        end
        C.lastValue=0;C.guardStart=nil;C.guardClock=0
        -- Never command a parked vehicle to turn.
        return
    end
    if C.waitingForMotion then C.waitingForMotion=false;log("MP: Lenkeingabe nach Anfahren aktiv") end
    local value=C.compute(vehicle,dt)
    if value==nil then return end
    spec.axisSide=value
    vehicle:raiseDirtyFlags(spec.dirtyFlag)
    if not C.networkPathLogged then
        C.networkPathLogged=true
        log("MP-CLIENT: Lenksignal ueber Drivable.axisSide / dirtyFlag aktiv")
    end
end
