-- GPS v0.9.4: experimental straight-pass steering, no throttle / brakes / turns.
-- Steering axis verified with v0.9.2: negative = left, positive = right.
GPSSteeringController={enabled=false,vehicle=nil,
    reason="Aus",lastValue=0,
    lastCross=0,lockedTrack=nil,
    hookInstalled=false,logClock=0,
    guardStart=nil,guardClock=0,
    waitingForMotion=false,networkSteeringValue=nil,
    injectingInput=false}
local C=GPSSteeringController
C.maxAssistSpeedKmh=30 -- Shared SP/MP speed limit (km/h).
-- Internal SP lane capture TEST to 30 km/h; predictive steering is unchanged.
-- 15/20 km/h and one ~24.8 km/h capture were confirmed in game; 30 km/h NOT tested.
-- Existing shared 30 km/h limit, MP restrictions and steering feedback stay unchanged.
C.captureMaxSpeedKmh=30
C.captureMaxHeading=math.rad(25)
C.captureMaxTimeMs=18000
local function holdOffsetLimit(width) return math.min(1.2,width*0.42) end
-- The dashed yellow guides mark +/- half an implement width from the lane.
-- Allow engagement at that boundary; 0.15m avoids round-off/position jitter.
-- The nearest physical lane is locked when GPS is enabled.
local function captureOffsetLimit(width) return width*0.5+0.15 end
-- Wider lateral captures get a longer timeout; capture steering is tuned separately below.
-- Preserve the legacy 18s window for near-lane activation.
local function captureTimeLimitMs(offset)
    return math.min(90000,C.captureMaxTimeMs+math.max(0,math.abs(offset)-2.5)*12000)
end
local function isMultiplayerClient() return g_client~=nil and g_server==nil end
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function log(msg) if GPSLogger then GPSLogger.info("GPS-LENK "..msg) end end
local function debug(msg) if GPSLogger and GPSLogger.debug then GPSLogger.debug("GPS-LENK "..msg) end end
-- Diagnostic-only instrumentation (2026-10-13). No intervention in steering maths.
-- Bounded INFO logging: at activation, in the first seconds of movement, then
-- once per 2 seconds, and once at disengagement. No per-frame log flood.
local function diagFmtNum(value, places)
    if type(value)~="number" then return "n/a" end
    return string.format("%."..tostring(places or 2).."f",value)
end
local function diagContext()
    local d=C.diagInfo or {}
    return string.format("phase=%s spur=%s speed=%skm/h abstand=%sm kursfehler=%sdeg dir=%s breite=%sm lenkSoll=%s lenkIst=%s rohAchse=%s mpAchse=%s",
        tostring(d.phase or "unbekannt"),tostring(C.lockedTrack or d.track or "n/a"),
        diagFmtNum(d.speed,1),diagFmtNum(d.offset,3),diagFmtNum(d.headingDeg,1),
        tostring(d.dir or "n/a"),diagFmtNum(d.width,2),
        diagFmtNum(d.desired,3),diagFmtNum(d.command,3),
        diagFmtNum(C.diagRawAxis,3),diagFmtNum(C.diagNativeRawAxis,3))
end
local function logDiagnostic(msg)
    if GPSConfig and GPSConfig.showDiagnostics == true then
        log("DIAG "..msg)
    end
end
local function captureActivationGeometry(vehicle,track)
    local d={phase="Aktivierung",track=track}
    local speed=(type(vehicle.getLastSpeed)=="function") and math.abs(vehicle:getLastSpeed()) or 0
    d.speed=speed
    -- Read-only context: validate expected objects before reading geometry.
    -- Unexpected engine/API errors are not swallowed; LS25 can log them.
    if GPSVehicleDetector==nil or type(GPSVehicleDetector.getPositionNode)~="function" or
        GPSABLineManager==nil or GPSImplementDetector==nil or
        type(GPSImplementDetector.getWidth)~="function" or
        type(getWorldTranslation)~="function" or type(localDirectionToWorld)~="function" then
        d.phase="Messdaten nicht verfuegbar"
        return d
    end
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if node==nil or node==0 then d.phase="Position fehlt";return d end
    local x,_,z=getWorldTranslation(node)
    local vx,_,vz=localDirectionToWorld(node,0,0,1)
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if a==nil or b==nil or type(a.x)~="number" or type(a.z)~="number" or
        type(b.x)~="number" or type(b.z)~="number" or
        type(x)~="number" or type(z)~="number" or
        type(vx)~="number" or type(vz)~="number" then
        d.phase="Geometrie unvollstaendig"
        return d
    end
    local dx,dz=b.x-a.x,b.z-a.z
    local len=math.sqrt(dx*dx+dz*dz)
    local fl=math.sqrt(vx*vx+vz*vz)
    if len<10 or fl<0.5 then d.phase="Richtung ungueltig";return d end
    local ux,uz=dx/len,dz/len
    vx,vz=vx/fl,vz/fl
    local dot=vx*ux+vz*uz
    local dir=dot>=0 and 1 or -1
    local tx,tz=ux*dir,uz*dir
    d.headingDeg=math.deg(math.atan2(vx*tz-vz*tx,vx*tx+vz*tz))
    d.dir=dir
    d.width=GPSImplementDetector.getWidth(vehicle)
    if type(d.width)=="number" and d.width>=0.5 then
        local live=(x-a.x)*(-uz)+(z-a.z)*ux
        -- TrackPosition uses precisely the same nearest-lane rule. Re-read
        -- it now to avoid locking a lane from its 150 ms update cache.
        -- Choose the lane from the DEVICE working center, not the tractor.
        local autoCorrection=0
        if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled then
            if type(GPSDeviceOffsetAuto.getCorrection)~="function" then
                d.phase="Geraete-Auto noch nicht bereit";return d
            end
            autoCorrection=GPSDeviceOffsetAuto.getCorrection(vehicle,dir)
            if type(autoCorrection)~="number" or autoCorrection~=autoCorrection then
                d.phase="Geraete-Auto noch nicht bereit";return d
            end
        end
        local spacing=GPSImplementDetector.getLaneSpacing(vehicle) or d.width
        d.track=math.floor((live-autoCorrection)/spacing+0.5)
        d.offset=live-autoCorrection-d.track*spacing
        d.deviceCorrection=autoCorrection
    end
    return d
end
function C.stop(reason)
    if C.enabled then
        log("AUS: "..tostring(reason))
        logDiagnostic("STOP grund="..tostring(reason).." | "..diagContext())
    end
    C.enabled=false; C.vehicle=nil;
         C.lastValue=0; C.lockedTrack=nil;
         C.reason=reason or "Aus"; C.logClock=0;
         C.guardStart=nil; C.guardClock=0;
         C.waitingForMotion=false;C.networkSteeringValue=nil;
        C.injectingInput=false;C.diagInfo=nil;
        C.diagRawAxis=nil;C.diagNativeRawAxis=nil;
        C.diagClock=0;C.diagElapsed=0;
        C.captureMode=false;C.captureElapsed=0;
        C.captureStable=0;C.captureTimeLimitMs=nil
end
local function rejectActivation(message)
    logDiagnostic("START ABGELEHNT: "..message)
    return message
end
function C.toggle(vehicle)
    if C.enabled then C.stop("Manuell ausgeschaltet"); return "GPS Lenkung AUS" end
    if not vehicle or not vehicle.spec_drivable then return rejectActivation("GPS: Kein lenkbares Fahrzeug") end
    if GPSSteeringDiagnostics and GPSSteeringDiagnostics.active then return rejectActivation("GPS: Erst Lenktest beenden") end
    if vehicle.spec_aiAutomaticSteering and vehicle.spec_aiAutomaticSteering.steeringEnabled then return rejectActivation("GPS: GIANTS Lenkassistent deaktivieren") end
    if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled then
        -- MP uses the same validated work-center measurement as SP.
        -- Local MP steering input, speed limit and safety watchdog are unchanged.
        if GPSDeviceOffsetAuto.getCorrection(vehicle,1)==nil then
            return rejectActivation("GPS: Geraete-Auto zuerst bei Stillstand einmessen")
        end
    end
    if not GPSABLineManager.a or not GPSABLineManager.b or not GPSTrackPosition.valid or GPSTrackPosition.track==nil then
        return rejectActivation("GPS: A/B und gueltige Spur erforderlich")
    end
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>C.maxAssistSpeedKmh then return rejectActivation("GPS: Aktivierung nur bis "..tostring(C.maxAssistSpeedKmh).." km/h") end
    local geometry=captureActivationGeometry(vehicle,GPSTrackPosition.track)
    if type(geometry.offset)~="number" or type(geometry.headingDeg)~="number"
        or type(geometry.width)~="number" or type(geometry.track)~="number" then
        return rejectActivation("GPS: Fahrzeugposition oder Spur noch nicht messbar ("..tostring(geometry.phase)..")")
    end
    local off=math.abs(geometry.offset)
    local headingAbs=math.abs(math.rad(geometry.headingDeg))
    -- SP 40-60cm errors previously used the very gentle hold controller.
    -- Switch to capture at >20cm or >3deg, without changing MP capture.
    local oldNormal=off<=holdOffsetLimit(geometry.width) and headingAbs<=0.35
    local missionInfo=g_currentMission and g_currentMission.missionDynamicInfo
    local multiplayerSession=isMultiplayerClient() or
        (missionInfo and missionInfo.isMultiplayer==true)
    local normal=multiplayerSession and oldNormal or
        (off<=0.20 and headingAbs<=math.rad(3))
    local acquiring=not normal
    if acquiring then
        -- Experimental capture must not alter the currently tested MP steering path.
        if isMultiplayerClient() then
            return rejectActivation("GPS: Im MP erst auf Spur ausrichten (max 1,20 m / 20 Grad)")
        end
        if off>captureOffsetLimit(geometry.width) then
            return rejectActivation(string.format("GPS: Zu weit von Spur entfernt (%.2f m, max %.2f m)",off,captureOffsetLimit(geometry.width)))
        end
        if off>2.5 and headingAbs>math.rad(10) then
            return rejectActivation(string.format("GPS: Fuer Einspuren ab gelber Linie parallel ausrichten (%.1f Grad, max 10 Grad)",math.deg(headingAbs)))
        end
        if headingAbs>C.captureMaxHeading then
            return rejectActivation(string.format("GPS: Kurswinkel %.1f Grad zu gross (max 25 Grad)",math.deg(headingAbs)))
        end
        if speed>C.captureMaxSpeedKmh then
            return rejectActivation("GPS: Spurerfassung nur bis "..tostring(C.captureMaxSpeedKmh).." km/h")
        end
    end
    if not C.install(vehicle) then return rejectActivation("GPS: Lenk-Hook nicht verfuegbar") end
    C.vehicle=vehicle;C.enabled=true;
        C.lockedTrack=geometry.track;C.lastValue=0;
        C.logClock=0;C.guardStart=nil;
        C.guardClock=0;C.waitingForMotion=false;
        C.networkSteeringValue=nil;C.injectingInput=false;
        C.networkPathLogged=false
    C.captureMode=acquiring;C.captureElapsed=0;C.captureStable=0;C.captureTimeLimitMs=acquiring and captureTimeLimitMs(off) or C.captureMaxTimeMs
    C.diagInfo=geometry
    C.diagRawAxis=nil;C.diagNativeRawAxis=nil;C.diagClock=0;C.diagElapsed=0
    logDiagnostic("START | "..diagContext())
    if acquiring then
        log(string.format("SPURERFASSUNG START: Spur %d | %.2f m | %.1f Grad | %.1f km/h | Limit %.0fs",C.lockedTrack,geometry.offset,geometry.headingDeg,speed,C.captureTimeLimitMs/1000))
    end
    local shown=(GPSTrackPosition and GPSTrackPosition.getDisplayNumber and GPSTrackPosition.getDisplayNumber(C.lockedTrack)) or C.lockedTrack
    C.reason="Aktiv | Spur "..tostring(shown)
    log("EIN: Spur "..tostring(C.lockedTrack).." (Anzeige "..tostring(shown)..") bei "..string.format("%.1f km/h",speed))
    return "GPS Lenkung EIN | Spur "..tostring(shown)
end
function C.compute(vehicle,dt,mpMode)
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
    local info=C.diagInfo or {}
    C.diagInfo=info
    info.phase="Kurswinkelpruefung";info.dir=dir;info.headingDeg=math.deg(heading)
    info.speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    info.offset=nil;info.width=nil;info.desired=nil;info.command=nil
    info.captureProjectedOffset=nil;info.captureLeadSeconds=nil
    local capture=C.captureMode==true
    if math.abs(heading)>(capture and C.captureMaxHeading or 0.35) then
        C.stop(capture and "Spurerfassung: Winkel zu gross" or "Winkel groesser 20 Grad");return nil
    end
    local width=GPSImplementDetector.getWidth(vehicle)
    if not width or width<0.5 then C.stop("Arbeitsbreite fehlt");return nil end
    local nx,nz=-uz,ux
    local autoCorrection=0
    if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled then
        autoCorrection=GPSDeviceOffsetAuto.getCorrection(vehicle,dir)
        if type(autoCorrection)~="number" or autoCorrection~=autoCorrection then
            C.stop("Geraete-Auto Messung nicht mehr gueltig");return nil
        end
    end
    -- Only the tractor steering target is displaced. A/B and its green
    -- working-center line and yellow work borders remain at their positions.
    local spacing=GPSImplementDetector.getLaneSpacing(vehicle) or width
    local offset=(x-a.x)*nx+(z-a.z)*nz-C.lockedTrack*spacing-autoCorrection
    info.deviceCorrection=autoCorrection
    info.phase="Spurabweichungspruefung";info.width=width;info.offset=offset
    if math.abs(offset)>(capture and captureOffsetLimit(width) or holdOffsetLimit(width)) then
        C.stop(capture and "Spurerfassung: Abweichung zu gross" or "Abweichung zu gross");return nil
    end
    -- Unbounded A/B guidance: no field-edge stop and no segment list.
    -- Empirical v0.9.3 logs: signed offset and heading ran AWAY from zero.
    -- Reverse BOTH feedback terms; check actual offset decrease in the safety watchdog.
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 5
    if capture then
        if speed>C.captureMaxSpeedKmh then C.stop("Spurerfassung: Ueber "..tostring(C.captureMaxSpeedKmh).." km/h");return nil end
        C.captureElapsed=(C.captureElapsed or 0)+(dt or 0)
        if C.captureElapsed>(C.captureTimeLimitMs or C.captureMaxTimeMs) then C.stop("Spurerfassung: Zeitlimit");return nil end
        -- Hand over only after 0.8 s consistently near the line. Thereafter,
        -- the original steering limits and feedback remain *identical*.
        if math.abs(offset)<=0.25 and math.abs(heading)<=math.rad(5) then
            C.captureStable=(C.captureStable or 0)+(dt or 0)
            if C.captureStable>=800 then
                C.captureMode=false
                C.captureStable=0
                C.guardStart=nil;C.guardClock=0
                log(string.format("SPURERFASSUNG FERTIG: Spur %d | %.2f m | %.1f Grad",C.lockedTrack,offset,math.deg(heading)))
            end
        else
            C.captureStable=0
        end
    end
    -- SP controller is unchanged. MP uses a forward-look target ON THE CURRENT
    -- TRACK rather than signed feedback into the server physics axis. The
    -- steering input sign was verified: positive=RIGHT, negative=LEFT.
    -- For a vehicle facing +Z and a target on its right (+X), atan2 returns
    -- a negative bearing. The *negative* of that bearing is the right-turn
    -- input, independent of A/B direction or travelling north/south.
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 5
    local desired,maxDelta
    if mpMode then
        local lookAhead=clamp(4.5+speed/3.6*1.6,5,10)
        local errX=targetX*lookAhead-offset*nx
        local errZ=targetZ*lookAhead-offset*nz
        local bearing=math.atan2(vx*errZ-vz*errX,vx*errX+vz*errZ)
        desired=clamp(-bearing*0.93,-0.19,0.19)
        maxDelta=0.00022*clamp(dt or 16,1,100)
    else
        local gainScale=clamp(8/math.max(speed,3),0.55,1.25)
        if capture then
            -- SP lane capture ONLY: anticipate lateral travel while steering
            -- turns the vehicle back parallel to the locked A/B track.
            -- The sign follows the signed offset and the A/B drive direction.
            -- At 15 km/h the vehicle crossed the line still ~11 degrees skewed;
            -- projected offset begins counter-steering BEFORE that crossing.
            local metersPerSecond=speed/3.6
            local leadSeconds=clamp(1.25+metersPerSecond*0.26,1.45,3.0)
            local projectedOffset=offset-dir*metersPerSecond*math.sin(heading)*leadSeconds
            info.captureProjectedOffset=projectedOffset
            info.captureLeadSeconds=leadSeconds
            -- SP capture only; MP and normal steering remain unchanged.
            desired=clamp((heading*1.10-projectedOffset*dir*0.31)*gainScale,-0.20,0.20)
        else
            desired=clamp((heading*1.10-offset*dir*0.23)*gainScale,-0.22,0.22)
        end
        maxDelta=(capture and 0.00042 or 0.00035)*clamp(dt or 16,1,100)
    end
    -- Rate limit to avoid abrupt wheel movements. dt is milliseconds.
    local command=C.lastValue+clamp(desired-C.lastValue,-maxDelta,maxDelta)
    info.phase=capture and "SP-Spurerfassung" or (mpMode and "MP-Regelung" or "SP-Regelung")
    info.speed=speed;info.desired=desired;info.command=command
    -- Early trend watchdog: prevents extended wrong-way correction if sign still wrong.
    -- Observe absolute lateral error over a moving 2.2-second window.
    if C.guardStart==nil then C.guardStart=math.abs(offset); C.guardClock=0 end
    C.guardClock=C.guardClock+(dt or 0)
    if C.guardClock>=(mpMode and 3000 or 2200) then
        local growth=math.abs(offset)-C.guardStart
        debug(string.format("Trend: absStart=%.3f absNow=%.3f delta=%+.3f heading=%.3f cmd=%.3f",C.guardStart,math.abs(offset),growth,heading,command))
        if growth>(mpMode and 0.38 or 0.24) and math.abs(command)>0.04 then
            C.stop("Sicherheitsstopp: Spurabweichung waechst"); return nil
        end
        C.guardStart=math.abs(offset); C.guardClock=0
    end
    -- Log real steering calculations only while running, not at every physics call.
    C.diagClock=(C.diagClock or 0)+(dt or 0)
    C.diagElapsed=(C.diagElapsed or 0)+(dt or 0)
    if C.diagClock>=((C.diagElapsed or 0)<3000 and 500 or 2000) then
        C.diagClock=0
        logDiagnostic("FAHRT | "..diagContext())
        if capture and info.captureProjectedOffset~=nil then
            logDiagnostic(string.format("CAPTURE-VORHALT: offset=%+.3fm voraussicht=%+.3fm horizont=%.2fs speed=%.1fkm/h lenk=%+.3f",
                offset,info.captureProjectedOffset,info.captureLeadSeconds or 0,speed,command))
        end
    end
    C.lastValue=command;C.lastCross=offset
    C.reason=string.format("Spur %d | %d cm | Lenk %.2f | frei",C.lockedTrack,math.floor(math.abs(offset)*100+0.5),command)
    C.logClock=C.logClock+(dt or 0)
    if C.logClock>=1600 then
        C.logClock=0
        debug(string.format("Spur=%d, speed=%.1f, offset=%.2f, heading=%.3f, steer=%.3f",C.lockedTrack,speed,offset,heading,command))
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
            C.diagRawAxis=type(axisSide)=="number" and axisSide or nil
            if speed>C.maxAssistSpeedKmh then
                C.stop("Geschwindigkeit ueber "..tostring(C.maxAssistSpeedKmh).." km/h")
            elseif C.captureMode and speed>C.captureMaxSpeedKmh then
                C.stop("Spurerfassung: Ueber "..tostring(C.captureMaxSpeedKmh).." km/h")
            elseif speed<2 then
                -- Paused at standstill (also while parked with handbrake):
                -- GPS stays ON, but NEVER sends steering corrections while stopped.
                -- Keep the chosen lane and start again without another key press.
                if not C.waitingForMotion then
                    C.waitingForMotion=true
                    C.reason="Aktiv (Stillstand) | Spur "..tostring(C.lockedTrack)
                    log("PAUSE: GPS bleibt beim Anhalten aktiv | Spur "..tostring(C.lockedTrack))
                    if C.diagInfo then C.diagInfo.phase="Stillstand";C.diagInfo.speed=speed end
                    logDiagnostic("PAUSE | "..diagContext())
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
                    if C.diagInfo then C.diagInfo.phase="Anfahren";C.diagInfo.speed=speed end
                    logDiagnostic("ANFAHREN | "..diagContext())
                end
                local v=C.compute(self,dt)
                if v~=nil then axisSide=v end
            end
        end
        return original(self,axisForward,axisSide,doHandbrake,dt,...)
    end
    vehicle.updateVehiclePhysics=wrapper
    if vehicle.updateVehiclePhysics~=wrapper then
        log("Hook fehlgeschlagen: Zuweisung nicht uebernommen");return false
    end
    C.hookedVehicles[vehicle]=original;C.hookInstalled=true
    if g_client~=nil and g_server==nil and type(vehicle.setSteeringInput)=="function" then
        local originalInput=vehicle.setSteeringInput
        vehicle.setSteeringInput=function(self,value,isAnalog,deviceCategory,...)
            if C.enabled and self==C.vehicle and not C.injectingInput then
                C.diagNativeRawAxis=type(value)=="number" and value or nil
                if type(value)=="number" and math.abs(value)>0.25 then
                    C.stop("MP: Manueller Lenkeingriff")
                elseif C.networkSteeringValue~=nil then
                    -- Even continuous wheel/gamepad callbacks must not override
                    -- the GPS's normal Drivable input before onUpdate consumes it.
                    value=C.networkSteeringValue
                    isAnalog=true
                end
            end
            return originalInput(self,value,isAnalog,deviceCategory,...)
        end
    end
    log("Fahrzeug-Hook aktiv: "..tostring(vehicle.getName and vehicle:getName() or vehicle))
    return true
end

-- Dedicated MP: feed GPS into the game's NORMAL driver input path.
-- Drivable:onUpdate integrates lastInputValues.axisSteer into axisSide,
-- updates the vehicle's physical steering state and replicates its own dirty
-- flags. Writing axisSide directly after onUpdate bypasses that integration
-- and can make the visible wheel disagree with the actual command.
function C.updateNetworkSteering(dt,vehicle)
    if g_client==nil or g_server~=nil or not C.enabled then return end
    -- If the previous native call raised an error, do not send further input.
    -- The engine logs the exception; this guard resets the injection state.
    if C.injectingInput then C.stop("MP: Vorherige Lenkeingabe nicht abgeschlossen");return end
    if vehicle==nil or vehicle~=C.vehicle then C.stop("MP: Fahrzeug verlassen/gewechselt");return end
    if vehicle.isClient~=true or vehicle.spec_drivable==nil then
        C.stop("MP: Kein lokales Drivable-Fahrzeug");return
    end
    if type(vehicle.getIsEntered)=="function" and not vehicle:getIsEntered() then
        C.stop("MP: Fahrer ausgestiegen");return
    end
    local spec=vehicle.spec_drivable
    if type(vehicle.setSteeringInput)~="function" or type(vehicle.raiseDirtyFlags)~="function" or spec.dirtyFlag==nil then
        C.stop("MP: Drivable-Lenkeingang nicht verfuegbar");return
    end
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>C.maxAssistSpeedKmh then C.stop("GPS maximal "..tostring(C.maxAssistSpeedKmh).." km/h");return end
    if spec.doHandbrake and speed>=2 then C.stop("MP: Handbremse");return end
    if speed<2 then
        if not C.waitingForMotion then
            C.waitingForMotion=true
            log("MP: GPS wartet bei Stillstand auf Weiterfahrt")
            if C.diagInfo then C.diagInfo.phase="MP-Stillstand";C.diagInfo.speed=speed end
            logDiagnostic("MP-PAUSE | "..diagContext())
        end
        C.lastValue=0;C.guardStart=nil;C.guardClock=0;C.networkSteeringValue=0
        return
    end
    if C.waitingForMotion then
        C.waitingForMotion=false;log("MP: Lenkeingabe nach Anfahren aktiv")
        if C.diagInfo then C.diagInfo.phase="MP-Anfahren";C.diagInfo.speed=speed end
        logDiagnostic("MP-ANFAHREN | "..diagContext())
    end
    local value=C.compute(vehicle,dt,true)
    if value==nil then return end
    -- v0.9.9.52: physical steering polarity in the normal Drivable input path
    -- differs from the previous direct physics-hook convention. Field feedback
    -- from v0.9.9.52: the vehicle turns AWAY from the target A/B line.
    -- Keep the guidance calculation and SP path unchanged, but invert ONLY the
    -- MP input sent into the native steering function. Do not invert the
    -- stored logical guidance value, which the deviation watchdog uses.
    local nativeInput=-value
    -- Log is the logical pre-inversion command, not the injected native input.
    C.networkSteeringValue=nativeInput
    -- Mark synthetic input so the manual-driver input wrapper doesn't treat
    -- TerraLine as a user intervention. The normal Drivable steering-wheel
    -- interpolation and multiplayer transmission execute in the game loop.
    C.injectingInput=true
    vehicle.setSteeringInput(vehicle,nativeInput,true,InputDevice and InputDevice.CATEGORY and InputDevice.CATEGORY.GAMEPAD)
    C.injectingInput=false
    C.nativeLogClock=(C.nativeLogClock or 0)+(dt or 0)
    if C.nativeLogClock>=1500 then
        C.nativeLogClock=0
        debug(string.format("MP INPUT: offset=%+.2fm logisch=%+.3f an Drivable=%+.3f",C.lastCross or 0,value,nativeInput))
    end
    if not C.networkPathLogged then
        C.networkPathLogged=true
        log("MP-CLIENT: normaler Lenkeingang aktiv (Lenkrad + Fahrzeug), Vorhaltepunkt, max "..tostring(C.maxAssistSpeedKmh).." km/h, v"..tostring(GPSConfig and GPSConfig.version or "?"))
    end
end
